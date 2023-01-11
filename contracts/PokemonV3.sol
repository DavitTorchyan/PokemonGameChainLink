// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
// import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
// import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

// import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

// import "hardhat/console.sol";

contract PokemonV3 is IERC721, Pausable, Ownable, VRFConsumerBaseV2 {
    string public name;
    string public symbol;
    uint256 public totalSupply; //totalSupply is also the id
    uint256 private randNonce;

    uint64 s_subscriptionId;
    address vrfCoordinator = 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D;
    bytes32 keyHash =
        0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;
    uint32 callbackGasLimit = 500000;
    uint32 numWords = 1;
    uint16 requestConfirmations = 3;
    address constant linkAddress = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    address constant vrfWrapperAddress =
        0x708701a1DfF4f478de54383E49a627eD4852C816;
    uint256 public randomNumber;
    VRFCoordinatorV2Interface COORDINATOR;

    using EnumerableSet for EnumerableSet.UintSet;
    EnumerableSet.UintSet private idSet;

    struct PokemonData {
        uint256 id;
        Dna dna;
        string name;
        uint256 age;
        uint256 birthTime;
        uint256 lastBattleTime;
        uint256 totalWins;
        uint256 totalLosses;
        uint256 strength;
        uint256 lastTrainingTime;
        bool inABattle;
    }

    struct BattleRequest {
        bool requested;
        uint256 requestTime;
    }

    struct Dna {
        uint256 hat;
        uint256 head;
        uint256 body;
        uint256 legs;
    }

    struct Battle {
        address requester;
        address accepter;
        uint256 requesterPokId;
        uint256 accepterPokId;
    }

    event BattleStarted(
        address indexed opponent1,
        address indexed opponent2,
        uint256 pokemon1Id,
        uint256 pokemon2Id,
        uint256 startTime
    );
    event BattleEnded(
        address indexed winner,
        address indexed loser,
        uint256 winnerPokemonId,
        uint256 loserPokemonId,
        uint256 endTime,
        uint256 winnerProb,
        uint256 loserProb
    );

    // tokenId => PokemonData
    mapping(uint256 => PokemonData) private pokemons;
    // pending battle from id to id
    mapping(uint256 => mapping(uint256 => BattleRequest)) public pendingBattles;
    mapping(address => uint256) private balances;
    mapping(uint256 => address) private ownerOfPokemon;
    mapping(address => mapping(address => mapping(uint256 => bool)))
        private allowances;
    // account => all owned pokemon ids
    mapping(address => EnumerableSet.UintSet) ownedPokemonId;
    // random number requestId => battle
    mapping(uint256 => Battle) public battles;

    constructor(
        uint64 subscriptionId,
        string memory name_,
        string memory symbol_
    ) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
        name = name_;
        symbol = symbol_;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address) {
        return ownerOfPokemon[_tokenId];
    }

    function allowance(
        address _owner,
        address _approved,
        uint256 _tokenId
    ) public view returns (bool) {
        return allowances[_owner][_approved][_tokenId];
    }

    function pokemon(uint256 id) public view returns (PokemonData memory) {
        return (pokemons[id]);
    }

    function mint() external whenNotPaused {
        require(balanceOf(msg.sender) < 2, "You can only mint two pokemons!");

        totalSupply += 1;
        ownerOfPokemon[totalSupply] = msg.sender;
        balances[msg.sender] += 1;
        pokemons[totalSupply] = PokemonData({
            id: totalSupply,
            dna: _randomDna(),
            name: name,
            age: 0,
            birthTime: block.timestamp,
            lastBattleTime: 0,
            totalWins: 0,
            totalLosses: 0,
            strength: _randomStrength(),
            lastTrainingTime: 0,
            inABattle: false
        });
        ownedPokemonId[msg.sender].add(totalSupply);

        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function getSet(address user) public view returns (uint256[] memory) {
        return ownedPokemonId[user].values();
    }

    function transfer(address _to, uint256 _tokenId) external whenNotPaused {
        require(ownerOfPokemon[_tokenId] == msg.sender, "Not your Pokemon!");

        ownerOfPokemon[_tokenId] = _to;
        balances[msg.sender] -= 1;
        balances[_to] += 1;
        ownedPokemonId[msg.sender].remove(_tokenId);
        ownedPokemonId[_to].add(_tokenId);

        emit Transfer(msg.sender, _to, _tokenId);
    }

    function approve(
        address _approved,
        uint256 _tokenId
    ) external whenNotPaused {
        require(ownerOfPokemon[_tokenId] == msg.sender, "Not your Pokemon!");

        if (allowances[msg.sender][_approved][_tokenId] == true) {
            allowances[msg.sender][_approved][_tokenId] = false; //calling approve on an already approved token disapproves it
        } else {
            allowances[msg.sender][_approved][_tokenId] = true;
            emit Approval(msg.sender, _approved, _tokenId);
        }
    }

    function transferFrom(
        address _owner,
        address _recepient,
        uint256 _tokenId
    ) external whenNotPaused {
        require(
            allowances[_owner][msg.sender][_tokenId] == true,
            "NFT not approved!"
        );

        ownerOfPokemon[_tokenId] = _recepient;
        balances[_owner] -= 1;
        balances[_recepient] += 1;
        ownedPokemonId[_owner].remove(_tokenId);
        ownedPokemonId[_recepient].add(_tokenId);

        emit Transfer(_owner, _recepient, _tokenId);
    }

    function _randomDna() private returns (Dna memory) {
        uint256 maxNumber = 16;
        uint256 hat = (uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))
        ) % (maxNumber));

        randNonce++;
        uint256 head = (uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))
        ) % (maxNumber));

        randNonce++;
        uint256 body = (uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))
        ) % (maxNumber));

        randNonce++;
        uint256 legs = (uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))
        ) % (maxNumber));

        Dna memory randDna = Dna({
            hat: hat,
            head: head,
            body: body,
            legs: legs
        });

        return (randDna);
    }

    function getDna(uint256 id) public view returns (Dna memory) {
        return (pokemon(id).dna);
    }

    function _randomStrength() private view returns (uint256 amount) {
        uint256 maxNumber = 400;
        uint256 minNumber = 100;
        amount =
            uint256(
                keccak256(
                    abi.encodePacked(block.timestamp, msg.sender, block.number)
                )
            ) %
            (maxNumber - minNumber);
        amount += minNumber;

        return amount;
    }

    function requestBattle(
        uint256 ownId,
        address opponent,
        uint256 oppId
    ) external whenNotPaused {
        require(
            ownerOfPokemon[ownId] == msg.sender &&
                ownerOfPokemon[oppId] == opponent,
            "Please enter pokemons you/your opponent own."
        );
        require(
            block.timestamp - pokemons[ownId].lastTrainingTime >= 1 days &&
                block.timestamp - pokemons[oppId].lastTrainingTime >= 1 days,
            "Can not request battle while in training cooldown!"
        );
        require(
            ownerOfPokemon[oppId] != msg.sender,
            "Can not request a fight between your own pokemons!"
        );
        pendingBattles[ownId][oppId] = BattleRequest({
            requested: true,
            requestTime: block.timestamp
        });
    }

    function acceptBattle(uint256 ownId, uint256 oppId) external whenNotPaused {
        require(ownerOfPokemon[ownId] == msg.sender, "Not your pokemon!");
        require(
            pokemons[ownId].strength >= 100,
            "Strength lower than 100, your pokemon needs training!"
        );
        require(
            !pokemons[ownId].inABattle && !pokemons[oppId].inABattle,
            "Pokemons currently in a battle!"
        );
        if (
            block.timestamp - pendingBattles[oppId][ownId].requestTime >= 1 days
        ) {
            pendingBattles[oppId][ownId].requested = false;
        }
        require(
            pendingBattles[oppId][ownId].requested,
            "No such pending battle!"
        );
        requestRandomWords(ownerOf(oppId), msg.sender, oppId, ownId);
    }

    function rejectBattle(uint256 ownId, uint256 oppId) external whenNotPaused {
        require(ownerOfPokemon[ownId] == msg.sender, "Not your pokemon!");
        require(
            pendingBattles[oppId][ownId].requested == true,
            "No such pending battle!"
        );
        pendingBattles[oppId][ownId].requested = false;
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        randomNumber = randomWords[0];
        address opponent = battles[requestId].requester;
        uint256 ownId = battles[requestId].accepterPokId;
        uint256 oppId = battles[requestId].requesterPokId;
        battle(ownId, oppId, opponent);
    }

    function requestRandomWords(
        address _requester,
        address _accepter,
        uint256 requesterId,
        uint256 accepterId
    ) internal returns (uint256 requestId) {
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        battles[requestId] = Battle({
            requester: _requester,
            accepter: _accepter,
            requesterPokId: requesterId,
            accepterPokId: accepterId
        });
        return requestId;
    }

    function battle(
        uint256 ownId,
        uint256 oppId,
        address opponent
    ) private whenNotPaused {
        require(
            ownerOfPokemon[oppId] == opponent,
            "Opponent does'nt own that pokemon!"
        );
        require(
            block.timestamp - pokemons[ownId].lastBattleTime >= 600 &&
                block.timestamp - pokemons[oppId].lastBattleTime >= 600,
            "Pokemons still in cooldown!"
        );

        PokemonData storage pokemon1 = pokemons[oppId];
        PokemonData storage pokemon2 = pokemons[ownId];
        pokemon1.lastBattleTime = block.timestamp;
        pokemon2.lastBattleTime = block.timestamp;
        pokemon1.inABattle = true;
        pokemon2.inABattle = true;
        emit BattleStarted(msg.sender, opponent, ownId, oppId, block.timestamp);
        uint256 combinedStrength = pokemon1.strength + pokemon2.strength;
        uint256 pokemon1WinProb = (pokemon1.strength * 100) / combinedStrength;
        uint256 pokemon2WinProb = 100 - pokemon1WinProb;
        randNonce++;
        uint256 winningNumber = (randomNumber % 100) + 1;

        if (winningNumber <= pokemon1WinProb) {
            pokemon1.totalWins += 1;
            pokemon1.strength += pokemon1WinProb;
            if (pokemon1.strength > 1500) {
                pokemon1.strength = 1500;
            }
            pokemon2.totalLosses += 1;
            pokemon2.strength -= pokemon2WinProb / 2;
            emit BattleEnded(
                opponent,
                ownerOf(ownId),
                oppId,
                ownId,
                block.timestamp,
                pokemon1WinProb,
                pokemon2WinProb
            );
        } else {
            pokemon2.totalWins += 1;
            pokemon2.strength += pokemon2WinProb;
            if (pokemon2.strength > 1500) {
                pokemon2.strength = 1500;
            }
            pokemon1.totalLosses += 1;
            pokemon1.strength -= pokemon1WinProb / 2;
            emit BattleEnded(
                ownerOf(ownId),
                opponent,
                ownId,
                oppId,
                block.timestamp,
                pokemon2WinProb,
                pokemon1WinProb
            );
        }

        pokemon1.inABattle = false;
        pokemon2.inABattle = false;
    }

    function trainPokemon(uint256 id) external whenNotPaused {
        require(ownerOfPokemon[id] == msg.sender, "Not your pokemon!");
        require(
            pokemons[id].strength < 100,
            "Pokemon doesn't need training yet!"
        );
        require(
            pokemons[id].inABattle != true,
            "Can not train during a battle!"
        );
        pokemons[id].strength = 100;
        pokemons[id].lastTrainingTime = block.timestamp;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function supportsInterface(
        bytes4 interfaceId
    ) external view override returns (bool) {}

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external override {}

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override {}

    function setApprovalForAll(
        address operator,
        bool _approved
    ) external override {}

    function getApproved(
        uint256 tokenId
    ) external view override returns (address operator) {}

    function isApprovedForAll(
        address owner,
        address operator
    ) external view override returns (bool) {}
}
