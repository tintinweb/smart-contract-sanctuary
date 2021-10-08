// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./IERC20.sol";
import "./Ownable.sol";

/// @author ECIO Engineering Team
/// @title Pre-Sale Smart Contract
contract Presales is Ownable {
    
    uint256 private constant LOT1_LOT2 = 1;
    uint256 private constant LOT3 = 2;
    
    //maximum BUSD per account.
    uint256 private constant MAXIMUM_BUSD_PER_ACCOUNT  = 200000000000000000000;
    
    //BUSD token address.
    address public busdTokenAddress;
  
    //lotsStartTime is start timestamp of each pre-sale lot.
    mapping(uint => uint) public lotsStartTime;
    
    //lotsEndTime is start timestamp of each pre-sale lot.
    mapping(uint => uint) public lotsEndTime;

    //lotsTokenPool is total token of each pre-sale lot.
    mapping(uint => uint) public lotsTokenPool;

    //lotsToken
    mapping(uint => uint) public lotsToken;
    
    //accountBalances is user's balances BUSD Token.
    mapping(address => uint) public accountBalances;
    
    //accountLotId use to keep id of pre-sale lot.
    mapping(address => uint) public accountLotId;
    
    //lot's balances.
    mapping(uint => uint) public lotsBalances;
   
   //lotsAccountCount
    mapping(uint => uint) public lotsAccountCount;

   //BuyPresale Event
    event BuyPresale(address indexed _from, uint _amount);
   
    
    //Validate the account has registered or not ? 
    modifier hasWhitelistRegistered(address _account){
        require(lotId(_account) != 0, "The account is not whitelist listed.");
        _;
    }
    
    //Validate start and end timestamp to allow users to access buying function.
    modifier isPresaleOpen(address _account){
       uint _lotId = accountLotId[_account];
       require(lotsStartTime[_lotId] !=0 && lotsEndTime[_lotId] !=0 ,"Pre-sale hasn't started.");
       require(lotsStartTime[_lotId] <= timeNow(), "Pre-sale hasn't started.");
       require(lotsEndTime[_lotId] >= timeNow(), "Pre-sale has closed.");
        _;
    }

    uint private timestamp;
    function setTimeNow(uint _timestamp) public onlyOwner{
        timestamp = _timestamp;
    }

    function timeNow() internal view returns(uint){
        if(timestamp != 0){
            return timestamp;
        }
        return block.timestamp;
    }

    function setBUSDTokenAddress(address _address) public onlyOwner{
        busdTokenAddress = _address;
    }

    function canAccessPresale(address _account) public view returns(uint){
        
        uint _lotId = accountLotId[_account];

        if(_lotId == 0){
            return 0;
        }

        require(lotsStartTime[_lotId] !=0 && lotsEndTime[_lotId] !=0 ,"Pre-sale hasn't started.");

        if (timeNow() >= lotsStartTime[_lotId] && timeNow() <= lotsEndTime[_lotId]){
            //Opened
            return 2;
        }else{

            //Waiting Open
            return 1;
        }
    }

    /**
    * @dev token pool number of lots. 
    */
    function tokenPoolPerLot(uint _lotId) public view returns(uint) {
        return lotsTokenPool[_lotId];
    }


    function tokenPerLot(uint _lotId) public view returns(uint) {
        return lotsToken[_lotId];
    }



    /**
    * @dev SetPresaleTime is function for setup pre-sale's timestamp.
    * @param _lotId lotId of pre-sale
    * @param _startTime start timestamp
    * @param _endTime end timestamp
    * @param _tokenPool number of token in lot
    */
    function setPresaleTime(uint _lotId, uint _startTime, uint _endTime, uint _tokenPool) external onlyOwner {
        lotsStartTime[_lotId] = _startTime;
        lotsEndTime[_lotId]   = _endTime;
        lotsTokenPool[_lotId] = _tokenPool;
        lotsToken[_lotId] = _tokenPool;
    }
    
    function moveTokenPoolFromLoT1Lot2ToLot3() public onlyOwner{
        lotsTokenPool[LOT3] = lotsTokenPool[LOT3] + lotsTokenPool[LOT1_LOT2];
        lotsTokenPool[LOT1_LOT2] = 0;
    }

    /**
    * @dev ImportWhitelist is function for manually import addresses that are allowed to buying. 
    */
    function importWhitelist(address[] memory _accounts, uint[] memory _lotIds) public onlyOwner {
        for(uint256 i = 0; i < _accounts.length; i++){
            accountLotId[_accounts[i]] = _lotIds[i];
            accountBalances[_accounts[i]] = 0;
            lotsAccountCount[_lotIds[i]] = lotsAccountCount[_lotIds[i]] + 1;
        }
    }

    /**
    * @dev Show account's lotId
    */
    function lotId(address _account) public view returns(uint){
        return accountLotId[_account];
    }

    function tokenAvailableForBuying(address _account) private view returns(uint) {
        return MAXIMUM_BUSD_PER_ACCOUNT - accountBalances[_account];
    }

    /**
    * @dev The number of tokens available for buying.
    */
    function tokenAvailable(address _account) public view returns(uint) {
        
        uint _lotId = lotId(_account);
        uint _available =  tokenAvailableForBuying(_account);
        
        if(_lotId == LOT1_LOT2){
            return _available;

        }else if(_lotId == LOT3){
            if(lotsTokenPool[_lotId] >= MAXIMUM_BUSD_PER_ACCOUNT){
                  return _available;
            }else{

                if(lotsTokenPool[_lotId] <= _available){
                    return lotsTokenPool[_lotId];
                }
            }
        }

        return 0;
    }


    /**
    * @dev a function for transfer BUSD token to this contract address and waiting for claim ECIO Token later.
    */
    function buyPresale(address _account, uint _amount) external hasWhitelistRegistered(_account) isPresaleOpen(_account) {
       
        require(_amount > 0, "Your amount is too small.");

        IERC20 _token = IERC20(busdTokenAddress);
        uint _balance = _token.balanceOf(msg.sender);
        require(_balance >= _amount, "Your balance is insufficient.");


        uint _lotId = accountLotId[_account];
        uint _available = tokenAvailable(_account);
         
        require(_amount <= _available, "the token pool is insufficient.");
       
        //transfer token from user's account into this smart contract address.
        _token.transferFrom(msg.sender, address(this), _amount);
        
        //Increase user's balances.
        accountBalances[_account] = accountBalances[_account] + _amount;
        
        //Increase lot's balances.
        lotsBalances[_lotId] = lotsBalances[_lotId] + _amount;

       //Increase lot's TokenPool.
        lotsTokenPool[_lotId] = lotsTokenPool[_lotId] - _amount;
        
        emit BuyPresale(msg.sender, _amount);
    }
    

    /**
    * @dev ContractBalances is function to show Token balance in smart contract. 
    */
    function contractBalances(address _contractAddress) public view returns(uint)  {
        IERC20 _token = IERC20(_contractAddress);
        uint256 _balance = _token.balanceOf(address(this));
        return _balance;
    }
    

    /**
    * @dev Transfer is function to transfer token from contract to other account.
    */

    function transfer(address _contractAddress, address  _to, uint _amount) public onlyOwner {
        IERC20 _token = IERC20(_contractAddress);
        _token.transfer(_to, _amount);
    }

}