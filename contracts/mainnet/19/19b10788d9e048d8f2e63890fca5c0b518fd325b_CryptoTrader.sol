pragma solidity ^0.4.24;
/*
* 1st Crypto Trader (DTH)
*/
library SafeMath {
 function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     if (a == 0) {
         return 0;
     }
     uint256 c = a * b;
     assert(c / a == b);
     return c;
 }

 function div(uint256 a, uint256 b) internal pure returns (uint256) {
     // assert(b > 0); // Solidity automatically throws when dividing by 0
     uint256 c = a / b;
     // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
     return c;
 }

 function sub(uint256 a, uint256 b) internal pure returns (uint256) {
     assert(b <= a);
     return a - b;
 }

 function add(uint256 a, uint256 b) internal pure returns (uint256) {
     uint256 c = a + b;
     assert(c >= a);
     return c;
 }
}


contract CryptoTrader {
 using SafeMath for uint256;
 mapping(address => uint256) balances; // array with all balances
 mapping (address => mapping (address => uint256)) internal allowed;
 mapping (address => uint256) public ETHBalance; // array with spend ETH

 uint256 public totalSupply; // emitted tokens
 address public contract_owner_address;

 event Transfer(address indexed from, address indexed to, uint256 value);
 event Approval(address indexed owner, address indexed buyer, uint256 value);
 event Burn(address indexed burner, uint256 value);

 string public constant name = "Digital Humanity Token";
 string public constant symbol = "DHT";
 uint8 public decimals = 0;
 uint public start_sale = 1537434000; // start of presale Thu, 20 Sep 2018 09:00:00 GMT
 uint public presalePeriod = 61; // presale period in days
 address public affiliateAddress ;

 uint public maxAmountPresale_USD = 40000000; // 400,000 US dollars.
 uint public soldAmount_USD = 0; // current tokens sale amount in US dollars


 /* Initializes contract with initial supply tokens to the creator of the contract */
 constructor (
     uint256 initialSupply,
     address _affiliateAddress
 ) public {
     totalSupply = initialSupply;
     affiliateAddress = _affiliateAddress;
     contract_owner_address = msg.sender;
     balances[contract_owner_address] = getPercent(totalSupply,75); // tokens for selling
     balances[affiliateAddress] = getPercent(totalSupply,25); //  affiliate 15% developers 10%
 }

 /**
 * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
 *
 * Beware that changing an allowance with this method brings the risk that someone may use both the old
 * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
 * race condition is to first reduce the buyer&#39;s allowance to 0 and set the desired value afterwards:
 * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
 * @param _buyer The address which will spend the funds.
 * @param _value The amount of tokens to be spent.
 */
 function approve(address _buyer, uint256 _value) public returns (bool) {
     allowed[msg.sender][_buyer] = _value;
     emit Approval(msg.sender, _buyer, _value);
     return true;
 }

 /**
 * @dev Function to check the amount of tokens that an owner allowed to a buyer.
 * @param _owner address The address which owns the funds.
 * @param _buyer address The address which will spend the funds.
 * @return A uint256 specifying the amount of tokens still available for the buyer.
 */
 function allowance(address _owner, address _buyer) public view returns (uint256) {
     return allowed[_owner][_buyer];
 }

 /**
 * @dev Gets the balance of the specified address.
 * @param _owner The address to query the the balance of.
 * @return An uint256 representing the amount owned by the passed address.
 */
 function balanceOf(address _owner) public view returns (uint256 balance) {
     return balances[_owner];
 }

 /**
 * @dev Transfer tokens from one address to another
 * @param _from address The address which you want to send tokens from
 * @param _to address The address which you want to transfer to
 * @param _value uint256 the amount of tokens to be transferred
 */
 function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
     require(_to != address(0));
     require(_value <= balances[_from]);
     require(_value <= allowed[_from][msg.sender]);

     balances[_from] = balances[_from].sub(_value);
     balances[_to] = balances[_to].add(_value);
     allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
     emit Transfer(_from, _to, _value);
     return true;
 }

 /**
 * @dev transfer token for a specified address
 * @param _to The address to transfer to.
 * @param _value The amount to be transferred.
 */
 function transfer(address _to, uint256 _value) public returns (bool) {
     require(_to != address(0));
     require(_value <= balances[msg.sender]);

     // SafeMath.sub will throw if there is not enough balance.
     balances[msg.sender] = balances[msg.sender].sub(_value);
     balances[_to] = balances[_to].add(_value);
     emit Transfer(msg.sender, _to, _value);
     return true;
 }

 /**
 * @dev sale token for a specified address
 * @param _to The address to transfer to.
 * @param _value The amount to be transferred.
 * @param _eth_price spended eth for buying tokens.
 * @param _usd_amount spended usd for buying tokens.
 */
 function transferSale(address _to, uint256 _value, uint256 _eth_price, uint256 _usd_amount) public  returns (bool success) {
     transfer(_to, _value);
     ETHBalance[_to] = ETHBalance[_to].add(_eth_price);
     soldAmount_USD += _usd_amount;
     return true;
 }

 /**
 * @dev Burns a specific amount of tokens.
 * @param _value The amount of token to be burned.
 */
 function burn(uint256 _value) public {
     require(_value <= balances[msg.sender]);
     address burner = msg.sender;
     balances[burner] = balances[burner].sub(_value);
     totalSupply = totalSupply.sub(_value);
     emit Burn(burner, _value);
 }

 /**
 * @dev Refund request.
 * @param _to The address for refund.
 */
 function refund(address _to) public payable returns(bool){
     require(address(this).balance > 0);
     uint256 _value = balances[_to];
     uint256 ether_value = ETHBalance[_to];
     require(now > start_sale + presalePeriod * 1 days && soldAmount_USD < maxAmountPresale_USD);
     require(_value > 0);
     require(ether_value > 0);
     balances[_to] = balances[_to].sub(_value);
     balances[contract_owner_address] = balances[contract_owner_address].add(_value);
     ETHBalance[_to] = 0;
     approve(_to, ether_value);
     address(_to).transfer(ether_value);
     return true;
 }

 /**
 * @dev Deposit contrac.
 * @param _value The amount to be transferred.
 */
 function depositContrac(uint256 _value) public payable returns(bool){
     approve(address(this), _value);
     return  address(this).send(_value);
 }

 function getPercent(uint _value, uint _percent) internal pure returns(uint quotient){
     uint _quotient = _value.mul(_percent).div(100);
     return ( _quotient);
 }
}