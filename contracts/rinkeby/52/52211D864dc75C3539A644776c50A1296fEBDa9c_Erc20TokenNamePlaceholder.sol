/**
 *Submitted for verification at Etherscan.io on 2022-01-02
*/

pragma solidity ^0.4.23;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

library SafeMath {
    /**
     * @dev 두 부호 없는 정수의 합을 반환합니다.
     * 오버플로우 발생 시 예외처리합니다.
     *
     * 솔리디티의 `+` 연산자를 대체합니다.
     *
     * 요구사항:
     * - 덧셈은 오버플로우될 수 없습니다.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev 두 부호 없는 정수의 차를 반환합니다.
     * 결과가 음수일 경우 오버플로우입니다.
     *
     * 솔리디티의 `-` 연산자를 대체합니다.
     *
     * 요구사항:
     * - 뺄셈은 오버플로우될 수 없습니다.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev 두 부호 없는 정수의 곱을 반환합니다.
     * 오버플로우 발생 시 예외처리합니다.
     *
     * 솔리디티의 `*` 연산자를 대체합니다.
     *
     * 요구사항:
     * - 곱셈은 오버플로우될 수 없습니다.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // 가스 최적화: 이는 'a'가 0이 아님을 요구하는 것보다 저렴하지만,
        // 'b'도 테스트할 경우 이점이 없어집니다.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev 두 부호 없는 정수의 몫을 반환합니다. 0으로 나누기를 시도할 경우
     * 예외처리합니다. 결과는 0의 자리에서 반올림됩니다.
     *
     * 솔리디티의 `/` 연산자를 대체합니다. 참고: 이 함수는
     * `revert` 명령코드(잔여 가스를 건들지 않음)를 사용하는 반면, 솔리디티는
     * 유효하지 않은 명령코드를 사용해 복귀합니다(남은 모든 가스를 소비).
     *
     * 요구사항:
     * - 0으로 나눌 수 없습니다.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // 솔리디티는 0으로 나누기를 자동으로 검출하고 중단합니다.
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // 이를 만족시키지 않는 경우가 없어야 합니다.

        return c;
    }

    /**
     * @dev 두 부호 없는 정수의 나머지를 반환합니다. (부호 없는 정수 모듈로 연산),
     * 0으로 나눌 경우 예외처리합니다.
     *
     * 솔리디티의 `%` 연산자를 대체합니다. 이 함수는 `revert`
     * 명령코드(잔여 가스를 건들지 않음)를 사용하는 반면, 솔리디티는
     * 유효하지 않은 명령코드를 사용해 복귀합니다(남은 모든 가스를 소비).
     *
     * 요구사항:
     * - 0으로 나눌 수 없습니다.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract owned{

    address public owner;

    constructor ()public{
        owner = msg.sender;
    }

    function changeOwner(address newOwner) public onlyOwner{
        owner = newOwner;
    }

    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }
}

contract Erc20Token {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Erc20TokenNamePlaceholder is Erc20Token, owned {

    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint public decimals;

    uint _totalSupply;
    mapping(address => uint) _balanceOf;
    mapping(address => mapping(address => uint)) _allowance;
    mapping (bytes => bool) private _signatures;

    event Burn(address indexed from, uint amount);
    event Mint(address indexed from, uint amount);
    
    constructor(string tokenName, string tokenSymbol, uint tokenDecimals, uint tokenTotalSupply) public {
        name = tokenName;
        symbol = tokenSymbol;
        decimals = tokenDecimals;

        _totalSupply = tokenTotalSupply * 10**uint(decimals);
        _balanceOf[msg.sender] = _totalSupply;
    }

    function totalSupply() public view returns (uint){
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint balance){
        return _balanceOf[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining){
        return _allowance[tokenOwner][spender];
    }

    function transfer(address to, uint value) public returns (bool success){
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) public returns (bool success){
        require(_allowance[from][msg.sender] >= value);
        
        _allowance[from][msg.sender] -= value;
        _transfer(from, to, value);

        return true;
    }

    function approve(address spender, uint value) public returns (bool succes) {
        _allowance[msg.sender][spender] = value;
        return true;
    }

    function approveAndCall(address spender, uint value, bytes extraData) public returns (bool success){
        tokenRecipient _spender = tokenRecipient(spender);
        if(approve(spender, value)){
            _spender.receiveApproval(msg.sender, value, this, extraData);
            return true;
        }
    }

    function burnFrom(address from, uint amount) public onlyOwner returns(bool success) {
        require(_balanceOf[from] >= amount);
        require(_balanceOf[from] - amount <= _balanceOf[from]);

        if(owner != from){
            require(_allowance[msg.sender][from] >= amount);
        }

        _balanceOf[from] -= amount;
        _allowance[msg.sender][from] -= amount;
        _totalSupply -= amount;

        emit Burn(from, amount);

        return true;
    }

    function mintTo(address to, uint amount) public onlyOwner returns(bool success){
        require(_balanceOf[to] + amount >= _balanceOf[to]);
        require(_totalSupply + amount >= _totalSupply);

        _balanceOf[to] += amount;
        _totalSupply += amount;

        emit Mint(to, amount);

        return true;
    }

    function() public payable {
        require(false);
    }

    function _transfer(address from, address to, uint value) internal{
        require(to != 0x0);
        require(_balanceOf[from] >= value);
        require(_balanceOf[to] + value >= _balanceOf[to]);

        uint previousBalance = _balanceOf[from] + _balanceOf[to];

        _balanceOf[from] -= value;
        _balanceOf[to] += value;

        emit Transfer(from, to, value);

        assert(_balanceOf[from] + _balanceOf[to] == previousBalance);
    }

    function transferPreSigned(
        bytes _signature,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        public
        returns (bool)
    {
        require(_to != address(0));
        require(_signatures[_signature] == false);
        bytes32 hashedTx = transferPreSignedHashing(address(this), _to, _value, _fee, _nonce);

        address from = recover(hashedTx, _signature);
        require(from != address(0));
        require(_value.add(_fee) <= _balanceOf[from]);

        _balanceOf[from] = _balanceOf[from].sub(_value).sub(_fee);
        _balanceOf[_to] = _balanceOf[_to].add(_value);
        _balanceOf[msg.sender] = _balanceOf[msg.sender].add(_fee);
        _signatures[_signature] = true;

        emit Transfer(from, _to, _value);
        emit Transfer(from, msg.sender, _fee);
        return true;
    }

 
    function transferPreSignedHashing(
        address _token,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        public
        pure
        returns (bytes32)
    {
        
        return keccak256(abi.encodePacked(_token, _to, _value, _fee, _nonce));
    }

    /**
     * @notice Recover signer address from a message by using his signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param sig bytes signature, the signature is generated using web3.eth.sign()
     */
    function recover(bytes32 hash, bytes sig) public pure returns (address) {
      bytes32 r;
      bytes32 s;
      uint8 v;

      //Check the signature length
      if (sig.length != 65) {
        return (address(0));
      }

      // Divide the signature in r, s and v variables
      assembly {
        r := mload(add(sig, 32))
        s := mload(add(sig, 64))
        v := byte(0, mload(add(sig, 96)))
      }

      // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
      if (v < 27) {
        v += 27;
      }

      // If the version is correct return the signer address
      if (v != 27 && v != 28) {
        return (address(0));
      } else {
        return ecrecover(hash, v, r, s);
      }
    }
}