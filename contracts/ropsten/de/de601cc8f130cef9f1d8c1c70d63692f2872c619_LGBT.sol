pragma solidity ^0.4.19;

/*				Rainbow$ (LGBT) - The ERC20 Token supporting the LGBT Community.					*/
/*	==============================================================================================	*/
/*	  http://remix.ethereum.org/#optimize=false&version=soljson-v0.4.19+commit.c4cbbb05.js			*/
/*	This contract MUST be compiled with OPTIMIZATION=NO via Solidity v0.4.19+commit.c4cbbb05		*/
/*	Attempting to compile this contract with any earlier or later  build  of  Solidity  will		*/
/*	result in Warnings and/or Compilation Errors. Turning  on  optimization  during  compile		*/
/*	will prevent the contract code from being able to Publish and Verify properly. Thus,  it		*/
/*	is imperative that this contract be compiled with optimization off using v0.4.19 of  the		*/
/*	Solidity compiler, more specifically: v0.4.19+commit.c4cbbb05.					        		*/
/*	==============================================================================================	*/
/*				Rainbow$ (LGBT) - The ERC20 Token supporting the LGBT Community.					*/
/*	==============================================================================================	*/
/*							:	The following are the details of this token as it appears			*/
/*							:	on the Ethereum MainNet.											*/
/*	Token Name				:	Rainbow$															*/
/*	Version Number			:	V1.04.07.2018														*/
/*	Total Supply			:	84,000,000 Tokens													*/
/*	Contract Address		:	0xb957D92D7fEaE5be6877AA94997De6dcd36B65F4							*/
/*	Ticker Symbol			:	LGBT																*/
/*	Decimals				:	18																	*/
/*	Creator Address			:	0xB27595b32F2dfc36d280BF32Dee7CA1a563148fe							*/
/*	Via the Genesis Address	:	0x0000000000000000000000000000000000000000							*/
/*	Transaction				:	0xeed85dd48475bad57a7b06aba4780ae47e8d3473b1ce4218c9c24994188d4d40	*/
/*	==============================================================================================	*/
/*							:	The following are the details of this token as it appears			*/
/*							:	on the Ropsten Ethereum TestNet.									*/
/*	Token Name				:	Rainbow$															*/
/*	Version Number			:	V1.04.07.2018														*/
/*	Total Supply			:	84,000,000 Tokens													*/
/*	Contract Address		:	0xde601cC8f130cef9f1d8C1c70d63692F2872C619							*/
/*	Ticker Symbol			:	LGBT																*/
/*	Decimals				:	18																	*/
/*	Creator Address			:	0xB27595b32F2dfc36d280BF32Dee7CA1a563148fe							*/
/*	Via the Genesis Address	:	0x0000000000000000000000000000000000000000							*/
/*	Transaction				:	0x89c00066be3d7650834570dccfe94f2f261d43a1c90d14294e6cd5a594228131	*/
/*	==============================================================================================	*/
/*							:	The following are the details of this token as it appears			*/
/*							:	on the Rinkeby Ethereum TestNet.									*/
/*	Token Name				:	Rainbow$															*/
/*	Version Number			:	V1.04.07.2018														*/
/*	Total Supply			:	84,000,000 Tokens													*/
/*	Contract Address		:	0xde601cC8f130cef9f1d8C1c70d63692F2872C619							*/
/*	Ticker Symbol			:	LGBT																*/
/*	Decimals				:	18																	*/
/*	Creator Address			:	0xB27595b32F2dfc36d280BF32Dee7CA1a563148fe							*/
/*	Via the Genesis Address	:	0x0000000000000000000000000000000000000000							*/
/*	Transaction				:	0x730657c9573cf0be472fb9f67793fe447100b3b9205aa2a2403999e51521f7cf	*/
/*	==============================================================================================	*/
/*							:	The following are the details of this token as it appears			*/
/*							:	on the Kovan Ethereum TestNet.										*/
/*	Token Name				:	Rainbow$															*/
/*	Version Number			:	V1.04.07.2018														*/
/*	Total Supply			:	84,000,000 Tokens													*/
/*	Contract Address		:	0xde601cC8f130cef9f1d8C1c70d63692F2872C619							*/
/*	Ticker Symbol			:	LGBT																*/
/*	Decimals				:	18																	*/
/*	Creator Address			:	0xB27595b32F2dfc36d280BF32Dee7CA1a563148fe							*/
/*	Via the Genesis Address	:	0x0000000000000000000000000000000000000000							*/
/*	Transaction				:	0xdd1bb3677c8ab6721defb8f352a794c89e1bb698c3ffa5145d85de44c082948d	*/
/*	==============================================================================================	*/
/*	========================================================================================	*/
contract ERC20Basic {uint256 public totalSupply; function balanceOf(address who) public constant returns (uint256); function transfer(address to, uint256 value) public returns (bool); event Transfer(address indexed from, address indexed to, uint256 value);}
/*	========================================================================================	*/ 
/* ERC20 interface see https://github.com/ethereum/EIPs/issues/20 */
contract ERC20 is ERC20Basic {function allowance(address owner, address spender) public constant returns (uint256); function transferFrom(address from, address to, uint256 value) public returns (bool); function approve(address spender, uint256 value) public returns (bool); event Approval(address indexed owner, address indexed spender, uint256 value);}
/*	========================================================================================	*/ 
/*  SafeMath - the lowest gas library - Math operations with safety checks that throw on error */
library SafeMath {function mul(uint256 a, uint256 b) internal pure returns (uint256) {uint256 c = a * b; assert(a == 0 || c / a == b); return c;}
// assert(b > 0); // Solidity automatically throws when dividing by 0
// assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
function div(uint256 a, uint256 b) internal pure returns (uint256) {uint256 c = a / b; return c;}
function sub(uint256 a, uint256 b) internal pure returns (uint256) {assert(b <= a); return a - b;}
function add(uint256 a, uint256 b) internal pure returns (uint256) {uint256 c = a + b; assert(c >= a); return c;}}
/*	========================================================================================	*/ 
/*	Basic token Basic version of StandardToken, with no allowances. */
contract BasicToken is ERC20Basic {using SafeMath for uint256; mapping(address => uint256) balances;
function transfer(address _to, uint256 _value) public returns (bool) {balances[msg.sender] = balances[msg.sender].sub(_value); balances[_to] = balances[_to].add(_value); Transfer(msg.sender, _to, _value); return true;}
/*	========================================================================================	*/ 
/* Gets the balance of the specified address.
   param _owner The address to query the the balance of. 
   return An uint256 representing the amount owned by the passed address.
*/
function balanceOf(address _owner) public constant returns (uint256 balance) {return balances[_owner];}}
/*	========================================================================================	*/ 
/*  Implementation of the basic standard token. https://github.com/ethereum/EIPs/issues/20 */
contract StandardToken is ERC20, BasicToken {mapping (address => mapping (address => uint256)) allowed;
/*  Transfer tokens from one address to another
    param _from address The address which you want to send tokens from
    param _to address The address which you want to transfer to
    param _value uint256 the amout of tokens to be transfered
*/
function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {var _allowance = allowed[_from][msg.sender];
// Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
// require (_value <= _allowance);
balances[_to] = balances[_to].add(_value); balances[_from] = balances[_from].sub(_value); allowed[_from][msg.sender] = _allowance.sub(_value); Transfer(_from, _to, _value); return true;}
/*  Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    param _spender The address which will spend the funds.
    param _value The amount of Douglas Adams&#39; tokens to be spent.
*/
function approve(address _spender, uint256 _value) public returns (bool) {
//  To change the approve amount you must first reduce the allowance
//  of the adddress to zero by calling `approve(_spender, 0)` if it
//  is not already 0 to mitigate the race condition described here:
//  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
require((_value == 0) || (allowed[msg.sender][_spender] == 0)); allowed[msg.sender][_spender] = _value; Approval(msg.sender, _spender, _value); return true;}
/*  Function to check the amount of tokens that an owner allowed to a spender.
    param _owner address The of the funds owner.
    param _spender address The address of the funds spender.
    return A uint256 Specify the amount of tokens still available to the spender.   */
function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {return allowed[_owner][_spender];}}
/*	========================================================================================	*/ 
/*  The Ownable contract has an owner address, and provides basic authorization control
    functions, this simplifies the implementation of &quot;user permissions&quot;.    */
contract Ownable {address public owner;
/*  Throws if called by any account other than the owner.                   */
function Ownable() public {owner = msg.sender;} modifier onlyOwner() {require(msg.sender == owner);_;}
/*  Allows the current owner to transfer control of the contract to a newOwner.
    param newOwner The address to transfer ownership to.    */
function transferOwnership(address newOwner) public onlyOwner {require(newOwner != address(0)); owner = newOwner;}}
/*	========================================================================================	*/
contract LGBT is StandardToken, Ownable {
    string public constant name = &quot;Rainbow$&quot;;
        string public constant symbol = &quot;LGBT&quot;;
            string public version = &#39;V1.04.07.2018&#39;;
            uint public constant decimals = 18;
        uint256 public initialSupply;
    uint256 public unitsOneEthCanBuy;           /*  How many units of LGBT can be bought by 1 ETH?  */
uint256 public totalEthInWei;                   /*  WEI is the smallest unit of ETH (the equivalent */
                                                /*  of cent in USD or satoshi in BTC). We&#39;ll store  */
                                                /*  the total ETH raised via the contract here.     */
address public fundsWallet;                     /*  Where should ETH sent to the contract go?       */
    function LGBT () public {
        totalSupply = 84000000 * 10 ** decimals;
            balances[msg.sender] = totalSupply;
                initialSupply = totalSupply;
            Transfer(0, this, totalSupply);
        Transfer(this, msg.sender, totalSupply);
    unitsOneEthCanBuy = 1000; 		            /*  Set the contract price of the LGBT token        */
fundsWallet = msg.sender;                       /*  The owner of the contract gets the ETH sent     */
                                                /*  to the LGBT contract                            */
}function() public payable{totalEthInWei = totalEthInWei + msg.value; uint256 amount = msg.value * unitsOneEthCanBuy; require(balances[fundsWallet] >= amount); balances[fundsWallet] = balances[fundsWallet] - amount; balances[msg.sender] = balances[msg.sender] + amount;
Transfer(fundsWallet, msg.sender, amount);      /*  Broadcast a message to the blockchain           */
/*  Transfer ether to fundsWallet   */
fundsWallet.transfer(msg.value);}
/*  Approves and then calls the receiving contract */
function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {allowed[msg.sender][_spender] = _value; Approval(msg.sender, _spender, _value);
/*  call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn&#39;t have to include a contract in here just for this.
    receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
    it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.  */
if(!_spender.call(bytes4(bytes32(keccak256(&quot;receiveApproval(address,uint256,address,bytes)&quot;))), msg.sender, _value, this, _extraData)) { return; } return true;}
/*	Owner can transfer out any accidentally sent ERC20 tokens	*/
function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {return LGBT(tokenAddress).transfer(owner, tokens);}
}