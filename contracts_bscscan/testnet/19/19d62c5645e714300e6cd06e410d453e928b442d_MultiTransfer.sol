/**
 *Submitted for verification at BscScan.com on 2021-08-04
*/

pragma solidity ^0.4.26;

library SafeMath {

    /**
     * @dev Multiplies two numbers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two numbers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

interface ITRC21 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function decimals() external view returns (uint);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Fee(address indexed from, address indexed to, address indexed issuer, uint256 value);
}
contract TRC21 is ITRC21 {
    mapping (address => uint256) _balances;
    uint256 private _minFee=0;
    address private _issuer;
    uint public _decimals = 18;
    // Token name
    string public _name = 'MultiTransfer';

    // Token symbol
    string public _symbol = 'MULT';
    using SafeMath for uint256;


    mapping (address => mapping (address => uint256)) private _allowed;
    uint256 private _totalSupply=100000000 * 10**_decimals;
    constructor () public {
        _changeIssuer(msg.sender);
        _balances[msg.sender] = _totalSupply;

    }
    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function decimals() public view returns (uint256) {
        return _decimals;
    }
    /**
     * @dev Gets the token name.
     * @return string representing the token name
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev Gets the token symbol.
     * @return string representing the token symbol
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }
    /**
     * @dev  The amount fee that will be lost when transferring.
     */
    function minFee() public view returns (uint256) {
        return _minFee;
    }

    /**
     * @dev token's foundation
     */
    function issuer() public view returns (address) {
        return _issuer;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Estimate transaction fee.
     * @param value amount tokens sent
     */
    function estimateFee(uint256 value) public view returns (uint256) {
        return value.mul(0).add(_minFee);
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner,address spender) public view returns (uint256){
        return _allowed[owner][spender];
    }

    /**
     * @dev Transfers token's foundation to new issuer
     * @param newIssuer The address to transfer ownership to.
     */
    function _changeIssuer(address newIssuer) internal {
        require(newIssuer != address(0));
        _issuer = newIssuer;
    }
    /**
         * @dev Transfer tokens from one address to another
         * @param from address The address which you want to send tokens from
         * @param to address The address which you want to transfer to
         * @param value uint256 the amount of tokens to be transferred
         */
    function transferFrom(address from,	address to,	uint256 value)	public returns (bool) {
        uint256 total = value.add(_minFee);
        require(to != address(0));
        require(value <= total);
        require(total <= _allowed[from][msg.sender]);

        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(total);
        _transfer(from, to, value);
        _transfer(from, _issuer, _minFee);
        emit Fee(msg.sender, to, _issuer, _minFee);
        return true;
    }
    /**
     * @dev Transfer token for a specified address
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) public returns (bool) {
        uint256 total = value.add(_minFee);
        require(to != address(0));
        require(value <= total);
        _transfer(msg.sender, to, value);
        if (_minFee > 0) {
            _transfer(msg.sender, _issuer, _minFee);
            emit Fee(msg.sender, to, _issuer, _minFee);
        }
        return true;
    }
    /**
     * @dev Transfer token for a specified addresses
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal {
        require(value <= _balances[from]);
        require(to != address(0));
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }
}
contract TRC721 {

    function transferFrom(address from, address to, uint256 tokenId) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);
}
contract MultiTransfer is TRC21, Ownable {
    using SafeMath for uint256;
    uint256 fee = 0;
    address[] public feeTokenArr = [address(0x65428e80232961caea779ced606e16022b525083), address(0x52108202fd8ee1dad47d14cbfef5ed9329d4b55a)];
    address public ceoAddress = address(0xF4db30c35428c0eDa99C8FeaD3F063be36a05149);
    event TransferToken(ITRC21 _token, address from, address[] to, uint[] amounts);
    event TransferToken721(TRC721 _token, address from, address[] to, uint[] amounts);
    event Sent(address from, address[] to, uint[] amounts);
    event _withdrawFee();
    struct feeToken {
        address addresss;
        uint fee;
    }
    mapping(address => feeToken) public feeTokens;
    modifier onlyCeo() {
        require(msg.sender == ceoAddress, 'You have not permission to do this action !');
        _;
    }
    modifier onlyManager() {
        require(msg.sender == owner() || msg.sender == ceoAddress);
        _;
    }
    function getFeeToken() public view returns(address[] memory) {
        return feeTokenArr;
    }
    function setFeeToken(address _feeToken, uint _fee) internal {
        feeTokens[_feeToken] = feeToken(_feeToken, _fee);
    }
    function setFeeTokenArr(address[] _tokens, uint[] _fees) public onlyManager (){
        feeTokenArr = _tokens;
        for(uint256 i = 0; i < _tokens.length; i++) {

            setFeeToken(_tokens[i], _fees[i]);
        }
    }
    function calFee(address _feetoken, uint256 _amount) public view returns(uint256) {
        return _amount.mul(feeTokens[_feetoken].fee);
    }
    function transferMultiToken(ITRC21 token, address[] _addresses, uint256[] amounts, address _feetoken) checkArrayArgument(_addresses, amounts) public {
        require(validFiat(_feetoken), 'trc21 invalid !!!');
        ITRC21 feetoken = ITRC21(_feetoken);
        require(feetoken.transferFrom(msg.sender, address(this), calFee(_feetoken, amounts.length)));
        for (uint256 i = 0; i < _addresses.length; i++) {
            token.transferFrom(msg.sender, _addresses[i], amounts[i]);

        }
        emit TransferToken(token, msg.sender, _addresses, amounts);
    }

    modifier checkArrayArgument(address[] _receivers, uint256[] _amounts) {
        require(_receivers.length == _amounts.length && _receivers.length > 0);
        _;
    }
    function validFiat(address _trc21) public view returns (bool){
        bool valid = false;
        for(uint256 i = 0; i < feeTokenArr.length; i++) {

            if(_trc21 == feeTokenArr[i]) valid = true;
        }
        return valid;
    }
    function transferMultiToken721(TRC721 token, address[] _addresses, uint256[] _tokenIds, address _feetoken) checkArrayArgument(_addresses, _tokenIds) public {
        require(token.isApprovedForAll(msg.sender, address(this)));
        require(validFiat(_feetoken), 'trc21 invalid !!!');
        ITRC21 feetoken = ITRC21(_feetoken);
        require(feetoken.transferFrom(msg.sender, address(this), calFee(_feetoken, _tokenIds.length)));
        for (uint256 i = 0; i < _addresses.length; i++) {
            token.transferFrom(msg.sender, _addresses[i], _tokenIds[i]);

        }
        emit TransferToken721(token, msg.sender, _addresses, _tokenIds);
    }
    function transferMulti(address[] receivers, uint256[] amounts, address _feetoken) checkArrayArgument(receivers, amounts) public payable {
        require(validFiat(_feetoken), 'trc21 invalid !!!');
        ITRC21 feetoken = ITRC21(_feetoken);
        require(feetoken.transferFrom(msg.sender, address(this), calFee(_feetoken, amounts.length)));
        for (uint256 j = 0; j < amounts.length; j++) {
            receivers[j].transfer(amounts[j]);
        }
        emit Sent(msg.sender, receivers, amounts);
    }
    function setCeo(address _ceo) public onlyCeo{
        ceoAddress = _ceo;
    }
    function withdrawFee(ITRC21[] _tokens, uint[] _amounts) public onlyCeo{

        for(uint256 i = 0; i < _tokens.length; i++) {

            _tokens[i].transfer(msg.sender, _amounts[i]);
        }
        emit _withdrawFee();
    }
}