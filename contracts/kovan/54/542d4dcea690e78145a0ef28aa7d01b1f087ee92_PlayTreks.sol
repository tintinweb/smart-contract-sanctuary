/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.4;

// Adding ERC-20 tokens function for added balanceOfcontract Token {
//contract Token {
    //function transfer(address _to, uint _value) public returns (bool success);
    //function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    //function approve(address _spender, uint _value) public returns (bool success);
//}

// Adding only ERC-20 DAI functions that we need
interface DaiInterface {
    function transfer(address dst, uint wad) external returns (bool);
    function balanceOf(address guy) external view returns (uint);
    function transferFrom(address _from, address _to, uint _value)external view returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    //event Transfer(address indexed from, address indexed to, uint256 value);
    //event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface GenNFTInterface{
    function transfer(address user) external returns (bool success);
}

contract Dai{
    DaiInterface daitoken;

    constructor(){
        daitoken =  DaiInterface(0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa);     // Kovan
        //daitoken = DaiInterface(0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa);    // Rinkeby
    }
}

contract GenNFT is Dai{
    GenNFTInterface genft;
    
    constructor(){
        genft = GenNFTInterface(0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa);  //arbitrary address that should be changed
    }
}

contract PlayTreks is GenNFT {
    address public creator = msg.sender; // can withdraw funds after the successful is successfully funded and finished
    uint public start = block.timestamp;
    uint public end = block.timestamp + 60; // 1 min 
    uint public receivedDai = msg.value;        // receivedDai
    address public arbitrator;
    address public owner;
    address public relayer;
    uint32 public requestCancellationMinimumTime;
    uint256 public feesAvailableForWithdraw;
    uint8 constant ACTION_SELLER_CANNOT_CANCEL = 0x01; // Called when marking as paid or calling a dispute as the buyer
    uint8 constant ACTION_BUYER_CANCEL = 0x02;
    uint8 constant ACTION_SELLER_CANCEL = 0x03;
    uint8 constant ACTION_SELLER_REQUEST_CANCEL = 0x04;
    uint8 constant ACTION_RELEASE = 0x05;
    uint8 constant ACTION_DISPUTE = 0x06;
    
    struct Client {
        uint amountSent;
        uint returned;
        uint clientIndex;
    }
    
    struct Escrow {
        // Set so we know the trade has already been created
        bool exists;
        // 1 = unlimited cancel time
        uint32 sellerCanCancelAfter;
        // The total cost of gas spent by relaying parties. This amount will be
        // refunded/paid to playtreks once the escrow is finished.
        uint128 totalGasFeesSpentByRelayer;
        // nft address for the escrow
        address nft;
    }

    mapping(address => Client) public clientStructs;
    // Mapping of active trades. Key is a hash of the trade data
    mapping (bytes32 => Escrow) public escrows;
    mapping(address=> uint) public shares;
    address[] public clientList;
    address[] public ownersList;
    uint[] public ownersShares;
    
    event Withdrawal(address indexed to, uint amount);
    event Deposit(address indexed from, uint amount);
    event Returned(address indexed to, uint amount);
    event Balance(uint amount);
    event Created(bytes32 _tradeHash);
    event SellerCancelDisabled(bytes32 _tradeHash);
    event SellerRequestedCancel(bytes32 _tradeHash);
    event CancelledBySeller(bytes32 _tradeHash);
    event CancelledByBuyer(bytes32 _tradeHash);
    event Released(bytes32 _tradeHash);
    event DisputeResolved(bytes32 _tradeHash);
    
    constructor (address[] memory _owners, uint[] memory share){

        //target = _target * 1e18;     // in ether 10^18 or 1e18
        // target = _target * 10 *1e18; // hardcoded target = 10 DAI
        
        //end = _end;
        ownersList = _owners;  // list of owners
        ownersShares = share; // percentage shares of partners
        owner = msg.sender;
        arbitrator = msg.sender;
        relayer = msg.sender;
        requestCancellationMinimumTime = 24 hours; 
        // unix timestamp format. Example: 1613753999 = 19/02/2021 16:55 (UTC)
    }
    
    // the fallback function (even if Ether is sent along with the call).
    fallback() external payable { 
        emit Deposit(msg.sender, msg.value);
        emit Balance(address(this).balance);
    }
    
   receive() external payable {
        emit Deposit(msg.sender, msg.value);
        emit Balance(address(this).balance);
    }
    
    //withdraw dai function
    //function sendViaCall( uint amount, address payable _to) public payable {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        //uint amounts = amount * 1e18;
        //(bool sent, bytes memory data) = _to.call{value: amounts}("");
        //require(sent, "Failed to send Ether");
    //}
    
    // Creator needs to input the amount he wants to withdraw after the project is finished
    function withdrawAllDaiFunds() public onlyCreator {
        
        uint totalBalance = daitoken.balanceOf(address(this));
        for (uint i=0; i<ownersList.length; i++) {
            daitoken.transfer(ownersList[i], ownersShares[i]*totalBalance);
            emit Withdrawal(ownersList[i], ownersShares[i]*totalBalance);
        }
    }
    
     // Creator needs to input the amount he wants to withdraw at any time
    function withdrawDaiFunds(uint amount) public onlyCreator {
        uint amounts = amount *1e18;
        // check if gathered donations are equal or bigger than the set minimum target
        require(daitoken.balanceOf(address(this)) >= amounts, "Not enough Dai in balance");
        
        for (uint i=0; i<ownersList.length; i++) {
            daitoken.transfer(ownersList[i], ownersShares[i]*amounts);
            emit Withdrawal(ownersList[i], ownersShares[i]*amounts);
        }
    }
    
    function withdrawAllEthFunds() public onlyCreator {
        
        uint totalBalance = address(this).balance;        
        for (uint i=0; i<ownersList.length; i++) {
           address payable to = payable(ownersList[i]);
            to.transfer(ownersShares[i]*totalBalance);
            emit Withdrawal(ownersList[i], ownersShares[i]*totalBalance);
        }
    }
    
    function withdrawEthFunds(uint amount) public onlyCreator {
        uint amounts = amount *1e18;
        // check if gathered donations are equal or bigger than the set minimum target
        require( address(this).balance >= amounts, "Not enough Eth in balance");
       for (uint i=0; i<ownersList.length; i++) {
           address payable to = payable(ownersList[i]);
            to.transfer(ownersShares[i]*amounts);
            emit Withdrawal(ownersList[i], ownersShares[i]*amounts);
        }
       
        
    }
    
    function withdrawAllFunds() public onlyCreator{
        withdrawAllEthFunds();
        withdrawAllDaiFunds();
    }
    
    
    // show DAI balance of SC  
    function balanceDai() public view returns(uint) {
        // return DAI balance on this SC
        return daitoken.balanceOf(address(this));
    }
    
    // show Ether balance of SC  
    function balanceEth() public view returns(uint) {
        // return DAI balance on this SC
        return address(this).balance;
    }
    
    // get SC address
    function getSmartContractAddress() public view returns(address) {
        return address(this);
    }
    
    // get current timestamp
    function getCurrentTimeStamp() public view returns(uint) {
        return block.timestamp;
    }
    
    // create an escrow
    function createEscrow(
      /**
       * Create a new escrow and add it to `escrows`.
       * _tradeHash is created by hashing _tradeID, _seller, _buyer, _value and _fee variables. These variables must be supplied on future contract calls.
       * v, r and s is the signature data supplied from the api. The sig is keccak256(_tradeHash, _paymentWindowInSeconds, _expiry).
       */
      bytes16 _tradeID, // The unique ID of the trade, generated by app.playtreks api
      address _seller, // The selling party of the trade
      address _buyer, // The buying party of the trade
      uint256 _value, // The ether amount being held in escrow
      uint16 _fee, // The PlayTreks fee in 1/10000ths
      uint32 _paymentWindowInSeconds, // The time in seconds from contract creation that the buyer has to mark as paid
      uint32 _expiry, // Provided by playtreks. This transaction must be created before this time.
      address _nft_address,
      uint8 _v, // Signature value
      bytes32 _r, // Signature value
      bytes32 _s // Signature value from web3.eth.accounts.sign()
    ) payable external {
        bytes32 _tradeHash = keccak256(abi.encodePacked(_tradeID, _seller, _buyer, _value, _fee));
        require(!escrows[_tradeHash].exists); // Require that trade does not already exist
        require(ecrecover(keccak256(abi.encodePacked(_tradeHash, _paymentWindowInSeconds, _expiry)), _v, _r, _s) == relayer); // Signature must have come from the relayer
        require(block.timestamp < _expiry);
        require(msg.value == _value && msg.value > 0); // Check sent eth against signed _value and make sure is not 0
        uint32 _sellerCanCancelAfter = _paymentWindowInSeconds == 0 ? 1 : uint32(block.timestamp) + _paymentWindowInSeconds;
        escrows[_tradeHash] = Escrow(true, _sellerCanCancelAfter, 0, _nft_address);
        emit Created(_tradeHash);
    }
    
    function getEscrowAndHash(
      /**
       * Hashes the values and returns the matching escrow object and trade hash.
       * Returns an empty escrow struct and 0 _tradeHash if not found
       */
      bytes16 _tradeID,
      address _seller,
      address _buyer,
      uint256 _value,
      uint16 _fee
    ) view public returns (Escrow memory, bytes32) {
        bytes32 _tradeHash = keccak256(abi.encodePacked(_tradeID, _seller, _buyer, _value, _fee) );
        return (escrows[_tradeHash], _tradeHash);
    }
    
    function getEscrowFromHash(
      /**
       * send the trade hash and get the matching escrow object and trade hash.
       * Returns an empty escrow struct and 0 _tradeHash if not found
       */
      bytes32 _tradeHash
    ) view public returns (Escrow memory, bytes32) {
        return (escrows[_tradeHash], _tradeHash);
    }
    
    uint16 constant GAS_doDisableSellerCancel = 12100;
    function doDisableSellerCancel(
      /**
       * Stops the seller from cancelling the trade.
       * Can only be called by the buyer.
       * Used to mark the trade as paid, or if the buyer has a dispute.
       */
      bytes16 _tradeID,
      address _seller,
      address _buyer,
      uint256 _value,
      uint16 _fee,
      uint128 _additionalGas
    ) private returns (bool) {
        PlayTreks.Escrow memory _escrow;
        bytes32 _tradeHash;
        (_escrow, _tradeHash) = getEscrowAndHash(_tradeID, _seller, _buyer, _value, _fee);
        if (!_escrow.exists) return false;
        if(_escrow.sellerCanCancelAfter == 0) return false;
        escrows[_tradeHash].sellerCanCancelAfter = 0;
        emit SellerCancelDisabled(_tradeHash);
        if (msg.sender == relayer) {
          increaseGasSpent(_tradeHash, GAS_doDisableSellerCancel + _additionalGas);
        }
        return true;
    }
    
    uint16 constant GAS_doBuyerCancel = 36100;
    function doBuyerCancel(
      /**
       * Cancels the trade and returns the ether to the seller.
       * Can only be called the buyer.
       */
      bytes16 _tradeID,
      address _seller,
      address _buyer,
      uint256 _value,
      uint16 _fee,
      uint128 _additionalGas
    ) private returns (bool) {
        PlayTreks.Escrow memory _escrow;
        bytes32 _tradeHash;
        
        (_escrow, _tradeHash) = getEscrowAndHash(_tradeID, _seller, _buyer, _value, _fee);
        if (!_escrow.exists) return false;
        uint128 _gasFees = _escrow.totalGasFeesSpentByRelayer + (msg.sender == relayer ? (GAS_doBuyerCancel + _additionalGas) * uint128(tx.gasprice) : 0);
        delete escrows[_tradeHash];
        emit CancelledByBuyer(_tradeHash);
        transferMinusFees(_seller, _value, _gasFees, 0);
        return true;
    }

    uint16 constant GAS_doSellerCancel = 36100;
    function doSellerCancel(
      /**
       * Cancels the trade and returns the ether to the seller.
       * Can only be called the seller.
       * Can only be called if the payment window was missed by the buyer
       */
      bytes16 _tradeID,
      address _seller,
      address _buyer,
      uint256 _value,
      uint16 _fee,
      uint128 _additionalGas
    ) private returns (bool) {
        PlayTreks.Escrow memory _escrow;
        bytes32 _tradeHash;
        (_escrow, _tradeHash) = getEscrowAndHash(_tradeID, _seller, _buyer, _value, _fee);
        if (!_escrow.exists) return false;
        if(_escrow.sellerCanCancelAfter <= 1 || _escrow.sellerCanCancelAfter > block.timestamp) return false;
        uint128 _gasFees = _escrow.totalGasFeesSpentByRelayer + (msg.sender == relayer ? (GAS_doSellerCancel + _additionalGas) * uint128(tx.gasprice) : 0);
        delete escrows[_tradeHash];
        emit CancelledBySeller(_tradeHash);
        transferMinusFees(_seller, _value, _gasFees, 0);
        return true;
    }
    
    function transferMinusFees(address _to, uint256 _value, uint128 _totalGasFeesSpentByRelayer, uint16 _fee) private {
        uint256 _totalFees = (_value * _fee / 10000) + _totalGasFeesSpentByRelayer;
        if(_value - _totalFees > _value) return; // Prevent underflow
        feesAvailableForWithdraw += _totalFees; // Add the the pot for playtreks to withdraw
        daitoken.transfer(_to, _value - _totalFees);
    }
    
    function transferNft(address _to, uint256 _value, uint128 _totalGasFeesSpentByRelayer, uint16 _fee) private {
        uint256 _totalFees = (_value * _fee / 10000) + _totalGasFeesSpentByRelayer;
        if(_value - _totalFees > _value) return; // Prevent underflow
        feesAvailableForWithdraw += _totalFees; // Add the the pot for playtreks to withdraw
        genft.transfer(_to);
    }
    
    uint16 constant GAS_doSellerRequestCancel = 12100;
    function doSellerRequestCancel(
      /**
       * Called by the seller if the buyer is unresponsive
       * Can only be called on unlimited payment window trades (sellerCanCancelAfter == 1)
       * Sets the payment window to `requestCancellationMinimumTime` from now, in which it can be cancelled.
       */
      bytes16 _tradeID,
      address _seller,
      address _buyer,
      uint256 _value,
      uint16 _fee,
      uint128 _additionalGas
    ) private returns (bool) {
        // Called on unlimited payment window trades wheret the buyer is not responding
        PlayTreks.Escrow memory _escrow;
        bytes32 _tradeHash;
        
        (_escrow, _tradeHash) = getEscrowAndHash(_tradeID, _seller, _buyer, _value, _fee);
        if (!_escrow.exists) return false;
        if(_escrow.sellerCanCancelAfter != 1) return false;
        escrows[_tradeHash].sellerCanCancelAfter = uint32(block.timestamp) + requestCancellationMinimumTime;
        emit SellerRequestedCancel(_tradeHash);
        if (msg.sender == relayer) {
          increaseGasSpent(_tradeHash, GAS_doSellerRequestCancel + _additionalGas);
        }
        return true;
    }

    uint16 constant GAS_doResolveDispute = 36100;
    function resolveDispute(
      /**
       * Called by the arbitrator to resolve a dispute
       * Requires the signed ACTION_DISPUTE actionByte from either the buyer or the seller
       */
      bytes16 _tradeID,
      address _seller,
      address _buyer,
      uint256 _value,
      uint16 _fee,
      uint8 _v,
      bytes32 _r,
      bytes32 _s,
      uint8 _buyerPercent
    ) external onlyArbitrator {
        address _signature = ecrecover(keccak256(abi.encodePacked(_tradeID, ACTION_DISPUTE)), _v, _r, _s);
        require(_signature == _buyer || _signature == _seller);
        
        PlayTreks.Escrow memory _escrow;
        bytes32 _tradeHash;
    
        (_escrow, _tradeHash) = getEscrowAndHash(_tradeID, _seller, _buyer, _value, _fee);
        require(_escrow.exists);
        require(_buyerPercent <= 100);

        uint256 _totalFees = _escrow.totalGasFeesSpentByRelayer + GAS_doResolveDispute;
        require(_value - _totalFees <= _value); // Prevent underflow
        feesAvailableForWithdraw += _totalFees; // Add the the pot for localethereum to withdraw

        delete escrows[_tradeHash];
        emit DisputeResolved(_tradeHash);
        daitoken.transfer(_buyer, (_value - _totalFees) * _buyerPercent / 100);
        daitoken.transfer(_seller, (_value - _totalFees) * (100 - _buyerPercent) / 100);
    }
    
    function getRelayedSender(
      bytes16 _tradeID, // The unique ID of the trade, generated by localethereum.com
      uint8 _actionByte, // The desired action of the user, matching an ACTION_* constant
      uint128 _maximumGasPrice, // The maximum gas price the user is willing to pay
      uint8 _v, // Signature value
      bytes32 _r, // Signature value
      bytes32 _s // Signature value
    ) view private returns (address) {
        bytes32 _hash = keccak256(abi.encodePacked(_tradeID, _actionByte, _maximumGasPrice));
        require(tx.gasprice > _maximumGasPrice, "maximum gas price not enough");
        return ecrecover(_hash, _v, _r, _s);
    }
    
    uint16 constant GAS_doRelease = 36100;
    function doRelease(
      /**
       * Called by the seller to releases the funds for a successful trade.
       * Deletes the trade from the `escrows` mapping.
       */
      bytes16 _tradeID,
      address _seller,
      address _buyer,
      uint256 _value,
      uint16 _fee,
      uint128 _additionalGas
    ) private returns (bool) {
        PlayTreks.Escrow memory _escrow;
        bytes32 _tradeHash;
        
        (_escrow, _tradeHash) = getEscrowAndHash(_tradeID, _seller, _buyer, _value, _fee);
        if (!_escrow.exists) return false;
        uint128 _gasFees = _escrow.totalGasFeesSpentByRelayer + (msg.sender == relayer ? (GAS_doRelease + _additionalGas) * uint128(tx.gasprice) : 0);
        delete escrows[_tradeHash];
        emit Released(_tradeHash);
        transferNft(_buyer, _value, _gasFees, _fee);
        return true;
    }
    
    function relay(
      bytes16 _tradeID,
      address _seller,
      address _buyer,
      uint256 _value,
      uint16 _fee,
      uint128 _maximumGasPrice,
      uint8 _v,
      bytes32 _r,
      bytes32 _s,
      uint8 _actionByte,
      uint128 _additionalGas
    ) private returns (bool action) {
      address _relayedSender = getRelayedSender(_tradeID, _actionByte, _maximumGasPrice, _v, _r, _s);
      if (_relayedSender == _buyer) {
        if (_actionByte == ACTION_SELLER_CANNOT_CANCEL) {
          return doDisableSellerCancel(_tradeID, _seller, _buyer, _value, _fee, _additionalGas);
        } else if (_actionByte == ACTION_BUYER_CANCEL) {
          return doBuyerCancel(_tradeID, _seller, _buyer, _value, _fee, _additionalGas);
        }
      } else if (_relayedSender == _seller) {
        if (_actionByte == ACTION_RELEASE) {
          return doRelease(_tradeID, _seller, _buyer, _value, _fee, _additionalGas);
        } else if (_actionByte == ACTION_SELLER_CANCEL) {
          return doSellerCancel(_tradeID, _seller, _buyer, _value, _fee, _additionalGas);
        } else if (_actionByte == ACTION_SELLER_REQUEST_CANCEL){
          return doSellerRequestCancel(_tradeID, _seller, _buyer, _value, _fee, _additionalGas);
        }
      } else {
        return false;
      }
    }

    uint16 constant GAS_batchRelayBaseCost = 28500;
    function batchRelay(
      /**
       * Call multiple relay methods at once to save on gas.
       */
        bytes16[] memory _tradeID,
        address[] memory _seller,
        address[] memory  _buyer,
        uint256[] memory  _value,
        uint16[] memory  _fee,
        uint128[] memory  _maximumGasPrice,
        uint8[] memory  _v,
        bytes32[] memory  _r,
        bytes32[] memory  _s,
        uint8[] memory  _actionByte
    ) public returns (bool[] memory) {
        bool[] memory _results = new bool[](_tradeID.length);
        uint128 _additionalGas = uint128(msg.sender == relayer ? GAS_batchRelayBaseCost / _tradeID.length : 0);
        for (uint8 i=0; i<_tradeID.length; i++) {
            _results[i] = relay(_tradeID[i], _seller[i], _buyer[i], _value[i], _fee[i], _maximumGasPrice[i], _v[i], _r[i], _s[i], _actionByte[i], _additionalGas);
        }
        return _results;
    }
    
    function release(bytes16 _tradeID, address _seller, address _buyer, uint256 _value, uint16 _fee) external returns (bool){
      require(msg.sender == _seller);
      return doRelease(_tradeID, _seller, _buyer, _value, _fee, 0);
    }
    function disableSellerCancel(bytes16 _tradeID, address _seller, address _buyer, uint256 _value, uint16 _fee) external returns (bool) {
      require(msg.sender == _buyer);
      return doDisableSellerCancel(_tradeID, _seller, _buyer, _value, _fee, 0);
    }
    function buyerCancel(bytes16 _tradeID, address _seller, address _buyer, uint256 _value, uint16 _fee) external returns (bool) {
      require(msg.sender == _buyer);
      return doBuyerCancel(_tradeID, _seller, _buyer, _value, _fee, 0);
    }
    function sellerCancel(bytes16 _tradeID, address _seller, address _buyer, uint256 _value, uint16 _fee) external returns (bool) {
      require(msg.sender == _seller);
      return doSellerCancel(_tradeID, _seller, _buyer, _value, _fee, 0);
    }
    function sellerRequestCancel(bytes16 _tradeID, address _seller, address _buyer, uint256 _value, uint16 _fee) external returns (bool) {
      require(msg.sender == _seller);
      return doSellerRequestCancel(_tradeID, _seller, _buyer, _value, _fee, 0);
    }

    
    function relayRelease(bytes16 _tradeID, address _seller, address _buyer, uint256 _value, uint16 _fee, uint128 _maximumGasPrice, uint8 _v, bytes32 _r, bytes32 _s) external returns (bool) {
      return relay(_tradeID, _seller, _buyer, _value, _fee, _maximumGasPrice, _v, _r, _s, ACTION_RELEASE, 0);
    }
    
    function increaseGasSpent(bytes32 _tradeHash, uint128 _gas) private {
        /** Increase `totalGasFeesSpentByRelayer` to be charged later on completion of the trade.
         */
        escrows[_tradeHash].totalGasFeesSpentByRelayer += _gas * uint128(tx.gasprice);
    }
    
    function setArbitrator(address _newArbitrator) onlyCreator external {
        /**
         * Set the arbitrator to a new address. Only the owner can call this.
         * @param address _newArbitrator
         */
        arbitrator = _newArbitrator;
    }

    function setOwner(address _newOwner) onlyCreator external {
        /**
         * Change the owner to a new address. Only the owner can call this.
         * @param address _newOwner
         */
        owner = _newOwner;
    }

    function setRelayer(address _newRelayer) onlyCreator external {
        /**
         * Change the relayer to a new address. Only the owner can call this.
         * @param address _newRelayer
         */
        relayer = _newRelayer;
    }

    function setRequestCancellationMinimumTime(uint32 _newRequestCancellationMinimumTime) onlyCreator external {
        /**
         * Change the requestCancellationMinimumTime. Only the owner can call this.
         * @param uint32 _newRequestCancellationMinimumTime
         */
        requestCancellationMinimumTime = _newRequestCancellationMinimumTime;
    }

    function transferToken( address _transferTo, uint256 _value) onlyCreator external {
        /**
         * If ERC20 tokens are sent to this contract, they will be trapped forever.
         * This function is way for us to withdraw them so we can get them back to their rightful owner
         */
         daitoken.transfer(_transferTo, _value);
    }
    function transferTokenFrom( address _transferTo, address _transferFrom, uint256 _value) onlyCreator view external {
        /**
         * If ERC20 tokens are sent to this contract, they will be trapped forever.
         * This function is way for us to withdraw them so we can get them back to their rightful owner
         */
         daitoken.transferFrom(_transferTo, _transferFrom, _value);
    }
    function approveToken( address _spender, uint256 _value) onlyCreator external {
        /**
         * If ERC20 tokens are sent to this contract, they will be trapped forever.
         * This function is way for us to withdraw them so we can get them back to their rightful owner
         */
         daitoken.approve(_spender, _value);
    }
    
    // modifier so that only the project creator can call certain functions
    modifier onlyCreator {
        bool yes = false;
        for (uint i=0; i<ownersList.length; i++) {
            if(msg.sender == ownersList[i]){
                yes=true;
            }
        }
        require(yes = true, "Only the psrtners in this distribution can call this function");
        _;
    }
    
    modifier onlyArbitrator() {
        require(msg.sender == arbitrator);
        _;
    }
}