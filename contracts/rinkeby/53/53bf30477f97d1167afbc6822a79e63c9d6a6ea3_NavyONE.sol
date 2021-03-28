/**
 *Submitted for verification at Etherscan.io on 2021-03-28
*/

// SPDX-License-Identifier: Apache
pragma solidity =0.6.12;

library TransferHelper {
    function safeApprove(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}


contract fundTokenized  {
    using SafeMath for uint;

    string public symbol = 'N1T';
    string public  name = 'Navy1Token';
    uint8 public decimals = 18;
    uint256 public totalSupply = 0;

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);

    mapping(address => uint) balanceOf;
    mapping(address => uint) lockTillBlock;
    mapping(address => mapping(address => uint)) allowance;

    function _transfer(address from, address to, uint256 amount) public returns (bool success) {
        require(lockTillBlock[from] <= block.number, 'LOCKED');
        delete lockTillBlock[from];
        if (from != address(0)){
            balanceOf[from] = balanceOf[from].sub(amount);
        }
        if (to != address(0)){
            balanceOf[to] = balanceOf[to].add(amount);
        }
        emit Transfer(from, to, amount);
        return true;
    }

    function _mint(address to, uint256 tokens) internal {
        totalSupply = totalSupply.add(tokens);
        _transfer(address(0), to, tokens);
        lockTillBlock[to] = block.number + 1000; //Lock 1000 blocks to prevent any flashloan attacks.
    }

    function _burn(address from, uint256 tokens) internal {
        require (balanceOf[from] >= tokens);
        totalSupply = totalSupply.sub(tokens);
        _transfer(from, address(0), tokens);
    }

    function transfer(address to, uint256 tokens) public returns (bool success) {
        require (balanceOf[msg.sender] >= tokens);
        _transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint256 tokens) public returns (bool success) {
        allowance[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint256 tokens) public returns (bool success) {
        require(allowance[from][msg.sender] >= tokens);
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(tokens);
        _transfer(from, to, tokens);
        return true;
    }

}

contract NavyONE is Ownable, fundTokenized{
    struct valuedToken { 
       address token;       //token address
       address oracle;      //price oracle @ chainLink
       uint80  premium;     //price premium
       uint8   decimals;    //decimals for convert of price
       bool    stable;      //is stable coin
       bool    nt_tr;       //Not Transfer: if the token address is an nt_tr ERC20(cannot be transferred)
       bool    ac_inv;      //Accpect Invest: if invest of this token can be accepted
       bool    u_std;       //Usd Standard: true-> price in usd standard, false-> price in eth standard
    }
    valuedToken [] public valuedTokens; //valuedToken[0] is always ETH

    event UpdateValuedTokens(uint256 tokenIndex);

    function maintainValueTokenList (uint256 tokenIndex, address token, address oracle, uint256 parameter) public onlyOwner returns(bool)  {
        require(tokenIndex <= valuedTokens.length);
        if (parameter == 0){
            //delete token
            delete valuedTokens[tokenIndex];
            return true;
        }
        valuedToken memory inputToken = valuedToken(
            token, oracle,
            uint80(parameter>>12),
            uint8((parameter>>4)&0xFF),
            parameter & 8 != 0,
            parameter & 4 != 0,
            parameter & 2 != 0,
            parameter & 1 != 0
            );
        if (tokenIndex == valuedTokens.length){
            //new valued token
            valuedTokens.push(inputToken);
        }else{
            valuedTokens[tokenIndex] = inputToken;
        }
        emit UpdateValuedTokens(tokenIndex);
        return true;
    }
    

    uint256 BASE = 1e18;


    constructor () public{
        //push WETH
        valuedTokens.push(valuedToken(
            0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, //place holder for ETH, always at valuedTokens[0] 
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e, //ChainLink Rinkeby ETH/USD
            uint80(5*BASE/100),  //5% premium
            8, //decimals 18+8-18=8
            true,   //equals 1 ETH
            false,  //nt_tr
            true,   //accept invest
            false   //price in eth standard rather than in usd standard! < - (to save gas)
            ));
    }

    receive () external payable {} //accept direct ETH transfer

    function getTokenBalance (uint256 tokenIndex) public view returns(uint256)  {
        require (tokenIndex < valuedTokens.length, 'out of index');
        if (tokenIndex == 0){ //valuedToken[0] should be always ETH
            return address(this).balance;
        }else{
            return IERC20(valuedTokens[tokenIndex].token).balanceOf(address(this));
        }
    }

    function getTokenPrice (uint256 tokenIndex, uint256 eth2usd) internal view returns(uint256)  { //should be internal
        //return with based in u_std
        uint tokenPrice;
        int price;
        if (valuedTokens[tokenIndex].stable){//stable coin price ~ 1
            tokenPrice = 1;
        }else{
            (,price,,,) = AggregatorV3Interface(valuedTokens[tokenIndex].oracle).latestRoundData();
            if (price > 0){
                tokenPrice = uint(price);
            }else{
                tokenPrice = 0;
            }
        }
        if (valuedTokens[tokenIndex].u_std){
           return tokenPrice;
        }else{
            if (eth2usd == 0){
                (,price,,,) = AggregatorV3Interface(valuedTokens[0].oracle).latestRoundData();
                eth2usd = uint(price);
            }
           return tokenPrice.mul(eth2usd);
        }
    }
    
    function transferToken (uint256 tokenIndex, address to, uint256 amount) internal {
        if (tokenIndex == 0){
            TransferHelper.safeTransferETH(to, amount);
            return;
        }
        if (valuedTokens[tokenIndex].nt_tr == false){
            TransferHelper.safeTransfer(valuedTokens[tokenIndex].token, to, amount);
            return;
        }else{
            return;
        }
    }
    
    //final value denoted as decimals by BASE <- 10E18
    function getTotalValue () public view returns(uint256)  {
        uint256 eth2usd    =   getTokenPrice(0,0);
        uint256 totalValue =   0;
        uint256 tokenValue =   0;
        uint256 balance;
        for (uint256 i = 0; i < valuedTokens.length; i ++){
            balance = getTokenBalance(i);
            if (balance > 0){
                tokenValue = getTokenBalance(i).mul(getTokenPrice(i, eth2usd)).mul(BASE + valuedTokens[i].premium).div(BASE);
            }else{
                tokenValue = 0;
            }
            totalValue = totalValue.add(tokenValue.div(10**uint256(valuedTokens[i].decimals)));
        }
        return totalValue;
    }
    

    function calInvestValue (uint256 tokenIndex, uint256 amount) internal view returns(uint256)  { 
        //return in u_std BASED
        require (valuedTokens[tokenIndex].ac_inv, 'DECLINED');
        uint256 tokenValue = amount.mul(getTokenPrice(tokenIndex,0));
        return tokenValue.div(10**uint256(valuedTokens[tokenIndex].decimals));
    }
  
    

    event Invest (address indexed investor, address token, uint256 amount, uint256 valuePerToken);
    event Withdraw (address indexed towhom, uint256 amount);

    function invest (uint256 tokenIndex, uint256 amount) public payable returns(bool)  {
        uint256 investValue = calInvestValue(tokenIndex, amount);
        uint256 totalValue = getTotalValue();
        if (tokenIndex == 0){
            assert(msg.value >= amount);
        }else{
            TransferHelper.safeTransferFrom(valuedTokens[tokenIndex].token, msg.sender, address(this), amount);
        }
        uint256 tokenToBeMinted;
        uint256 valuePerToken;
        if (totalSupply == 0){
            tokenToBeMinted = investValue;
            valuePerToken    = BASE;
        }else{
            tokenToBeMinted = totalSupply.mul(BASE).div(totalValue).mul(investValue).div(BASE);
            valuePerToken   = totalValue.mul(BASE).div(totalSupply);
        }
        emit Invest(msg.sender, valuedTokens[tokenIndex].token, amount, valuePerToken);
        _mint(msg.sender, tokenToBeMinted);
        return true;
    }
    
    function withdraw (uint256 amount) public returns(bool)  {
        uint256 shareBased = amount.mul(BASE).div(totalSupply);
        _burn(msg.sender, amount);
        for (uint256 i = 0; i < valuedTokens.length; i ++){
            if(valuedTokens[i].nt_tr == false){
                if(getTokenBalance(i)>0){
                    transferToken(i, msg.sender, getTokenBalance(i)*shareBased.div(shareBased));
                }
            }
        }
        emit Withdraw(msg.sender, amount);
    }

    event ActiveManage();

    function activeManage(address addr, uint256 value, bytes calldata data) public onlyOwner{
        addr.call{value: value}(data);
        emit ActiveManage();
    }
    
}