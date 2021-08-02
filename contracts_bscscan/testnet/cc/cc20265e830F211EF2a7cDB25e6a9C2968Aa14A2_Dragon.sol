pragma solidity 0.8.0;
// SPDX-License-Identifier: Unlicensed

import "./IRandoms.sol";

interface Characters {
    function getInfo(uint256 _tokenId) external view returns (uint256, uint256, uint256, uint256, bool, uint256, uint256);
	function getStamina(uint256 _tokenId) external view returns (uint256);
	function evolve( address _to, uint256 _tokenId, string calldata _uri) external;
	function hatch(uint256 _tokenId, uint256 _rare, uint256 _class) external;
	function transferOwnership (address _newOwner) external;
	function ownerOf (uint256 _tokenId) external returns (address) ;
	function doneCombat(uint256 _tokenId, uint256 _receivedExp) external returns (uint256, uint256);
}

contract Dragon {
	IRandoms public randoms;
	Characters public characters;
	uint256 public mintCharacterFee;
	uint256 public hatchFee;
	address owner;
	uint256 public _newTokenID;
	
	// Intializing the state variable
    uint _randomNonce = 0;
    uint _maxRare = 6000;
    uint _maxClass = 15;
	uint256[256] private levelMultiplierRateTable;
	uint256[256] private baseReward;
	uint256 private baseExp;
	mapping(address => uint256) lastBlockNumberCalled;

	event FightOutcome(address indexed owner, uint256 indexed _tokenId, uint256 target, uint256 xpGain, uint256 ballGain);

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	modifier isCharacterOwner(uint256 character) {
		require(characters.ownerOf(character) == msg.sender, "Not the character owner");
		_;
	}

	modifier oncePerBlock(address user) {
		require(lastBlockNumberCalled[user] < block.number, "Only callable once per block");
		lastBlockNumberCalled[user] = block.number;
		_;
    }

	constructor(address _characters, uint256 newTokenID){
		characters = Characters(_characters);
		mintCharacterFee = 10000000000000000000;
		hatchFee = 1000000000000000000;
		_newTokenID = newTokenID;
		owner = msg.sender;
		levelMultiplierRateTable = [
			100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100,
			110, 110, 110, 110, 110, 110, 110, 110, 110, 110,
			120, 120, 120, 120, 120, 120, 120, 120, 120, 120,
			130, 130, 130, 130, 130, 130, 130, 130, 130, 130,
			140, 140, 140, 140, 140, 140, 140, 140, 140, 140,
			150, 150, 150, 150, 150, 150, 150, 150, 150, 150,
			160, 160, 160, 160, 160, 160, 160, 160, 160, 160,
			160
		];
		baseReward = [
			0, 5000000000000000000, 6670000000000000000, 8000000000000000000, 10000000000000000000, 13330000000000000000, 20000000000000000000, 5000000000000000000
		];
		baseExp = 100;
	}

	function getInfo(uint256 _tokenId) external view returns (uint256, uint256, uint256, uint256, bool, uint256, uint256) {
		return characters.getInfo(_tokenId);
	}

	function getStamina(uint256 _tokenId) external view returns (uint256) {
		return characters.getStamina(_tokenId);
	}

	function evolve( address _to, string calldata _uri) external oncePerBlock(msg.sender){
		_newTokenID++;
		return characters.evolve(_to, _newTokenID, _uri);
	}

	function hatch(uint256 _tokenId) external isCharacterOwner(_tokenId) oncePerBlock(msg.sender){
		( , , , , bool _isHatched, , ) = characters.getInfo(_tokenId);
		require(_isHatched == false, "This Character is hatched.");
		uint _rare = random(_maxRare, _tokenId);
		uint _class = random(_maxClass, _tokenId);
		return characters.hatch(_tokenId, _rare, _class);
	}

	function combat(uint256 _tokenId, uint256 _winrate) external isCharacterOwner(_tokenId) oncePerBlock(msg.sender){
		(
			uint256 _rare,
			,
			uint256 _Level,
			,
			bool _isHatched,
			uint256 stamina,
			
		) = characters.getInfo(_tokenId);
		require(_isHatched, "This Character is not hatched yet.");
		require(_winrate < 6, "Input parameters are incorrect");
		require(stamina > 0, "Input parameters are incorrect");
		uint256 _multiplierRate = levelMultiplierRateTable[_Level];
		uint256 _baseReward = baseReward[_rare];
		uint256 opportunity = random(1000, _tokenId);
		uint256 _receivedExp = random(10, _tokenId);
		uint256	_reward = _multiplierRate * _baseReward;
		bool isWin = false;
		if(_winrate == 1){
			if(opportunity < 900){
				_receivedExp = baseExp - _receivedExp;
				_reward = _reward;
				isWin = true;
			}
			characters.doneCombat(_tokenId, _receivedExp);
		}else if(_winrate == 2){
			if(opportunity < 800){
				_receivedExp = (baseExp - _receivedExp) * 110 / 100;
				_reward = _reward * 110 / 100;
				isWin = true;
			}
			characters.doneCombat(_tokenId, _receivedExp);
		}else if(_winrate == 3){
			if(opportunity < 700){
				_receivedExp = (baseExp - _receivedExp) * 115 / 100;
				_reward = _reward * 125 / 100;
				isWin = true;
			}
			characters.doneCombat(_tokenId, _receivedExp);
		}else if(_winrate == 4){
			if(opportunity < 600){
				_receivedExp = (baseExp - _receivedExp) * 120 / 100;
				_reward = _reward * 145 / 100;
				isWin = true;
			}
			characters.doneCombat(_tokenId, _receivedExp);
		}else if(_winrate == 5){
			if(opportunity < 500){
				_receivedExp = (baseExp - _receivedExp) * 130 / 100;
				_reward = _reward * 180 / 100;
				isWin = true;
			}
			characters.doneCombat(_tokenId, _receivedExp);
		}else{
			require(_winrate > 0, "Input parameters are incorrect"); 
		}
		emit FightOutcome(msg.sender, _tokenId, _winrate, _receivedExp, _reward);
	}

	function random(uint _max, uint256 _tokenId) internal returns (uint) {
		uint _randomNonceNew = _randomNonce + _tokenId;
		uint _random = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, _randomNonceNew))) % _max;
		if(_randomNonce == 9000000000000000000)
			_randomNonce = 1;
		_randomNonce++;
		return _random;
	}

	function transferCharactersOwnership(address _newOwner) external onlyOwner{
		return characters.transferOwnership( _newOwner );
	}
}