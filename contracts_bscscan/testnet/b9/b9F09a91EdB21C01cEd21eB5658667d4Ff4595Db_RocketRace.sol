// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./IRocketNft.sol";

interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the ERC token owner.
   */
  function getOwner() external view returns (address);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ether/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract RocketRace is Ownable{
   
    // All the needed info about race
    struct race {
        uint cost;               // Cost per member.0 means free race. 
        uint totalAmount;        // Total amount.
        uint startTimeStamp;     // Race starting time stamp.
        uint[10] contestant;     // Total Participants.
        uint32[3] winners;       // The winning rocketId.
        uint8 count;             // Total participants count
        bool status;             // Race status true means closed.
        uint level;              // 4.Cadet (initial level) 3.Engineer(0-40)
                                 // 2.Astronaut(40-60) 1.Elonet (60 above) 
        
    }
    
    // All the needed info about rocket
    struct rocket{
        uint256 rating;
        uint256 time;   // After this rocket can participte in other race
                        // initially 0 
    }
    mapping(uint => race ) public raceInfo;
    // RocketId => rating and time
    mapping(uint => rocket) public rocketInfo;
    //  raceIg => winnerof race 
    mapping(uint => mapping(uint => bool)) public winnerInfo;
   
    // Instance of token (collateral currency for race)
    IERC20 public token;
    // Instance of token
    IRocketNft public nftToken;
    // Total race counter
    uint public totalRace;
    // Winning percentages
    uint32[4] public pcent = [10, 40, 30, 20] ; 
    // The gasFee amount receiving address
    address public organizer; 
  
    // Event details
    event Race(uint raceId, uint levelType, uint totalRaceAmount);
    event EnterRace(uint raceID, uint tokenId, uint index, address caller);
    event RaceResult(uint raceId, uint timestamp, uint32[3] winnerIndex);

    constructor (IERC20 _token, IRocketNft _nftToken, address _organizer) {
        token = _token;
        nftToken = _nftToken;
        organizer = _organizer;
    }

    modifier isRaceExist(uint _raceId) {
        require(( _raceId > 0) && (_raceId <= totalRace), "Race is not exist");
        require( (raceInfo[_raceId].startTimeStamp > block.timestamp) && (!raceInfo[_raceId].status), "Invalid time");
       
        _;
    }

    modifier isRocketEligible(uint256 _tokenId) {
        require(nftToken.ownerOf(_tokenId) == msg.sender, "Invalid Rocket" );
        require( (rocketInfo[_tokenId].time == 0) || (rocketInfo[_tokenId].time < block.timestamp), "Already participated");
        _;
    }

    function createNewRace(uint _cost, uint _totalAmount, uint _raceEndingTime, uint _level) external onlyOwner {
        
        require( (_totalAmount > 0) && (_raceEndingTime > block.timestamp), "Invalid amount or time");
        require( (_level <= 4), "Invalid level");

        totalRace++;
        uint raceId = totalRace;
        raceInfo[raceId].cost = _cost;
        raceInfo[raceId].totalAmount = _totalAmount;
        raceInfo[raceId].startTimeStamp = _raceEndingTime; 
        raceInfo[raceId].level = _level;   

        emit Race(raceId, _level, _totalAmount);    
    } 

    function enterRace(uint _raceId, uint _index, uint _tokenId) external isRaceExist(_raceId) isRocketEligible(_tokenId){
         
        require(isEligible(_tokenId, raceInfo[_raceId].level), "Not eligible");
        require( (_index < 10) && (raceInfo[_raceId].contestant[_index] == 0), "Invalid index");

        _safeTransferFrom(msg.sender, address(this), raceInfo[_raceId].cost);

        raceInfo[_raceId].contestant[_index] = _tokenId;
        rocketInfo[_tokenId].time = raceInfo[_raceId].startTimeStamp;
        raceInfo[_raceId].count++;

        emit EnterRace(_raceId, _tokenId, _index, msg.sender);

    } 

    function isEligible(uint _tokenId, uint _level) internal view returns(bool){

        if(_level == 0){
            return true;
        } else if(_level == 1){
            if(rocketInfo[_tokenId].rating > 60){return true;} else {return false;}
        }else if(_level == 2){
            if( (rocketInfo[_tokenId].rating > 40) && (rocketInfo[_tokenId].rating <= 60) ){return true;} else {return false;}
        }else if(_level == 3){
            if((rocketInfo[_tokenId].rating > 0) && (rocketInfo[_tokenId].rating <= 40)){return true;} else {return false;}
        }else if(_level == 4){
            if(rocketInfo[_tokenId].rating == 0 ){return true;} else {return false;}
        } else { return false;}
    
    }

    function raceResult(uint _raceId, uint _randomNo) external onlyOwner {
        require((raceInfo[_raceId].startTimeStamp < block.timestamp), "Invalid time");
        require(!raceInfo[_raceId].status, "Race closed");
        require(raceInfo[_raceId].count == 10, "race not filled yet");
        
        uint32[3] memory result = getRandomNo(_randomNo, _raceId);
        raceInfo[_raceId].winners = result;
        uint totalAmount = raceInfo[_raceId].totalAmount;
        uint32[4] memory _pcent = pcent;
        
        _safeTransfer(nftToken.ownerOf(result[0]), (totalAmount*_pcent[1]/100) );
        _safeTransfer(nftToken.ownerOf(result[1]), (totalAmount*_pcent[2]/100) );
        _safeTransfer(nftToken.ownerOf(result[2]), (totalAmount*_pcent[3]/100) );
        _safeTransfer(organizer, (totalAmount*_pcent[0]/100) );

        setRating(_raceId);
        raceInfo[_raceId].status = true;

        emit RaceResult(_raceId, block.timestamp, result);

    }

    function _safeTransferFrom(address _from, address _to, uint _value) private {
        require(token.transferFrom(_from, _to, _value), "transferFrom failed");
    }

    function _safeTransfer(address _to, uint _value) private {
        require(token.transfer(_to, _value), "transferFrom failed");
    }

    function setRating(uint _raceId) internal {
        if(raceInfo[_raceId].level == 4){
           initialLevel(_raceId);
        }else {
            updateRating(_raceId);
        }
    }

    function initialLevel( uint _raceId) internal {
        uint tokenId;
        for(uint i=0; i<10; i++){
            tokenId = raceInfo[_raceId].contestant[i];
            rocketInfo[tokenId].rating = gen(tokenId);
        }
        updateRating(_raceId);   
    }

    function updateRating(uint _raceId) internal{
        uint32[3] memory result =  raceInfo[_raceId].winners;

        rocketInfo[result[0]].rating =  rocketInfo[result[0]].rating + 4;
        rocketInfo[result[1]].rating =  rocketInfo[result[0]].rating + 3;
        rocketInfo[result[2]].rating =  rocketInfo[result[0]].rating + 2;
    }

    function gen(uint tokenId) internal view returns(uint){
        if(getGen(tokenId) <= 3) {
            return 27;
        } else if(getGen(tokenId) <=9){
            return 17;
        } else {
            return 7;
        }
    }

    function getGen(uint _tokenId) internal view returns (uint generation) {
        (,,,,,,,,generation) = nftToken.getRocket(_tokenId); 
    }

    function getRandomNo(uint _externalRandomNumber, uint _raceId) private  returns(uint32[3] memory _winners){
        bytes32 _hash = keccak256(
            abi.encode(
                blockhash(block.number),
                block.coinbase,
                gasleft(),
                _externalRandomNumber
            )
        );
        uint _randomNumber  = uint(_hash);

        uint32 numberRepresentation;
        uint totalWinners=0;
        for(uint i = 0; i < 10; i++){
            bytes32 hashOfRandom = keccak256(abi.encodePacked(_randomNumber, i, (_raceId+i)));
            numberRepresentation =  uint32(raceInfo[_raceId].contestant[(uint(hashOfRandom)%(9))]);

            if( !winnerInfo[_raceId][numberRepresentation]) {
                _winners[totalWinners] = numberRepresentation;
                winnerInfo[_raceId][numberRepresentation] = true;
                totalWinners++;
                if(totalWinners == 3){
                    return _winners;
                }
            }
        }
    }

    function raceDetaild(uint raceId) external view returns(race memory){
        return raceInfo[raceId];
    }

}