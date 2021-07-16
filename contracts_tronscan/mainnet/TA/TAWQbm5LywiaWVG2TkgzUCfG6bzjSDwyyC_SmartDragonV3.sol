//SourceUnit: SmartDragonV3.sol

pragma solidity >=0.5.16;

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

contract Context {
    constructor () { }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _tempOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        _tempOwner = address(0);
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _tempOwner = newOwner;
    }

    function acceptOwnership() public {
        require(_tempOwner == _msgSender(), "Ownable: caller is not the owner");
        emit OwnershipTransferred(_owner, _tempOwner);
        _owner = _msgSender();
        _tempOwner = address(0);
    }
}

contract TransferHelper {

    mapping(address => bool) internal specialToken;

    function safeApprove(address token, address to, uint value) internal returns (bool){
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal returns (bool){
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        if(specialToken[token]) {
            return success;
        }else{
            return success && (data.length == 0 || abi.decode(data, (bool)));
        }
    }

    function safeTransfer(address token, address to, uint256 value) internal returns(bool){
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        if(specialToken[token]) {
            return success;
        }else{
            return success && (data.length == 0 || abi.decode(data, (bool)));
        }
    }

    function safeBalanceOf(address token, address wallet) internal returns (uint){
        (bool _success, bytes memory data) = token.call(abi.encodeWithSelector(0x70a08231, wallet));
        if(_success) {
            (uint amount) = abi.decode(data, (uint));
            return amount;
        }
        return 0;
    }

    function safeAllowance(address token, address from, address to) internal returns (uint){
        (bool _success, bytes memory data) = token.call(abi.encodeWithSelector(0xdd62ed3e, from, to));
        if(_success) {
            (uint amount) = abi.decode(data, (uint));
            return amount;
        }
        return 0;
    }
}


contract SmartDragonV3 is Context, Ownable, TransferHelper {

    using SafeMath for uint256;

    struct User {
        address payable wallet;
        address sponsor;
        uint8 level;
    }

    mapping(address => User) public investors;
    mapping(uint8 => uint) public levels;
    mapping(address => uint8) public acceptedTokens; // contract address => decimals
    address public TokenUSDT;
    bytes private SECRET_KEY;
    mapping(bytes20 => bool) private _withdrawal_nonce;
    bool private pause_withdraw = false;
    bool private internal_payment = true;
    bool private pay_in_usdt = true;

    event Withdrawal(address indexed wallet, uint indexed amount);

    constructor(address _tokenUSDT, bytes memory key) public {
        SECRET_KEY = key;
        investors[_msgSender()] = User(_msgSender(), _msgSender(), 12);

        levels[1] =  50    * 1000000;
        levels[2] =  100   * 1000000;
        levels[3] =  250   * 1000000;
        levels[4] =  500   * 1000000;
        levels[5] =  1000  * 1000000;
        levels[6] =  2500  * 1000000;
        levels[7] =  5000  * 1000000;
        levels[8] =  7500  * 1000000;
        levels[9] =  10000 * 1000000;
        levels[10] = 15000 * 1000000;
        levels[11] = 20000 * 1000000;
        levels[12] = 30000 * 1000000;

        TokenUSDT = _tokenUSDT;
        acceptedTokens[TokenUSDT] = 6;
        specialToken[TokenUSDT] = true;
    }

    function setSpecialPermission(address token, bool p) public onlyOwner returns(bool) {
        specialToken[token] = p;
        return true;
    }

    function verify(address a, address c, address g, uint u, bytes20 n) internal returns (bool) {
        bytes20 _nonce = ripemd160(abi.encodePacked(a, c, g, u, SECRET_KEY));
        return _nonce == n;
    }

    function verify_withdraw(address a, address q, uint u, bytes20 t) internal returns (bool) {
        bytes20 tg = ripemd160(abi.encodePacked(a, q, u, SECRET_KEY));
        return tg == t;
    }

    function joinWithTRX(address cmp, address gap, bytes20 _nonce) external payable {
        require(verify(_msgSender(), cmp, gap, msg.value, _nonce), "Error: invalid transaction");
        require(investors[_msgSender()].level == 0, "Error: already joined");
        _registerUser(cmp, gap);
    }

    function joinWithTRC20Token(address token, address cmp, address gap, bytes20 _nonce) external payable {
        require(pay_in_usdt, "Error: not accepting USDT");
        require(verify(_msgSender(), cmp, gap, levels[1], _nonce), "Error: invalid transaction");
        require(approved(token, _msgSender(), levels[1]), "Error: unauthorised access");
        require(investors[_msgSender()].level == 0, "Error: already joined");
        require(acceptedTokens[token] != 0, "Error: token not accepted");
        safeTransferFrom(TokenUSDT, _msgSender(), address(this), levels[1]);
        _registerUser(cmp, gap);
    }

    function upgradeWithTRX(address cmp, address gap, uint8 level, bytes20 _nonce) external payable {
        require(verify(_msgSender(), cmp, gap, msg.value, _nonce), "Error: invalid transaction");
        _upgradeUser(level, cmp, gap);
    }

    function upgradeWithTRC20Token(address token, address cmp, address gap, uint8 level, bytes20 _nonce) external payable {
        require(pay_in_usdt, "Error: not accepting USDT");
        require(verify(_msgSender(), cmp, gap, levels[level], _nonce), "Error: invalid transaction");
        require(approved(token, _msgSender(), levels[level]), "Error: unauthorised access");
        require(acceptedTokens[token] != 0, "Error: token not accepted");
        safeTransferFrom(TokenUSDT, _msgSender(), address(this), levels[level]);
        _upgradeUser(level, cmp, gap);
    }

    function _upgradeUser(uint8 level, address cmp, address gap) internal {
        investors[_msgSender()].level = level;
        if(internal_payment) {
            _payCompensation(cmp, level);
            _payGP(gap, level);
        }
    }

    function _registerUser(address sponsor, address gap) internal{
        investors[_msgSender()] = User(_msgSender(), sponsor, 1);
        if(internal_payment){
            _payCompensation(sponsor, 1);
            _payGP(gap, 1);
        }
    }

    function _payCompensation(address a, uint8 l) internal{
        uint amount = 0;
        if(pay_in_usdt) {
            amount = levels[l].div(5);
            safeTransfer(TokenUSDT, a, amount);
        }else{
            amount = msg.value.div(5);
            payable(a).transfer(amount);
        }
    }

    function _payGP(address a, uint8 l) internal{
        uint amount = 0;
        if(pay_in_usdt) {
            amount = levels[l].div(10);
            safeTransfer(TokenUSDT, a, amount);
        }else{
            amount = msg.value.div(10);
            payable(a).transfer(amount);
        }
    }

    function _joinAndUpgrade(address payable u, address s, address c, address g, uint8 l, bool p) external payable onlyOwner {
        uint8 ll;
        if(investors[u].level == 0) {
            require(investors[s].level != 0, "Error: not a sponsor");
            investors[u] = User(u, s, l);
            ll = 1;
        }else{
            ll = investors[u].level + 1;
            investors[u].level = l;
        }

        if(p) {
            for(uint8 i = ll; i <= l; i++) {
                _payCompensation(c, i);
                _payGP(g, i);
            }
        }
    }

    function approved(address t, address a, uint u) public returns (bool) {
        return safeAllowance(t, a, address(this)) >= u;
    }

    function safeWithdrawTRX(address payable w, uint a) public onlyOwner returns (bool){
        w.transfer(a);
        return true;
    }

    function safeWithdrawTRC20(address token, address payable w, uint a) public onlyOwner returns (bool){
        return safeTransfer(token, w, a);
    }

    function transferMultiple(address token, address[] memory wallets, uint[] memory amounts) public onlyOwner {
        require(wallets.length == amounts.length, "Error");
        uint bal = safeBalanceOf( token, address(this) );
        for (uint8 i = 0; i < wallets.length; i++) {
            require( bal >= amounts[i], "Error: insufficient fund" );
            safeTransfer(token, wallets[i], amounts[i]);
            bal = bal.sub(amounts[i]);
        }
    }

    function withdraw(uint amount, address a, bytes20 _nonce) public returns (bool) {
        require(!pause_withdraw, "Error: withdrawal is paused");
        require(!_withdrawal_nonce[_nonce], "Error: invalid nonce");
        require(verify_withdraw(_msgSender(), a, amount, _nonce), "Error: invalid nonce");
        if(pay_in_usdt) {
            safeTransfer(TokenUSDT, _msgSender(), amount);
        }else{
            _msgSender().transfer(amount);
        }
        _withdrawal_nonce[_nonce] = true;
        emit Withdrawal(_msgSender(), amount);
        return true;
    }

    function approveTRC20(address token, address to, uint amount) public onlyOwner returns(bool) {
        return safeApprove(token, to, amount);
    }

    function addLevel(uint8 l, uint a) public onlyOwner {
        levels[l] = a * 1000000;
    }

    function addAcceptedToken(address token, uint8 dec) public onlyOwner returns(bool) {
        acceptedTokens[token] = dec;
        return true;
    }

    function updateSecretKey(bytes memory k) public onlyOwner {
        SECRET_KEY = k;
    }

    function updateWithdrawalPermission(bool b) public onlyOwner {
        pause_withdraw = b;
    }

    function updatePayInternal(bool b) public onlyOwner {
        internal_payment = b;
    }

    function updatePayMode(bool is_usdt) public onlyOwner {
        pay_in_usdt = is_usdt;
    }

    function failSafe() public onlyOwner returns (bool){
        updateWithdrawalPermission(true);
        updatePayInternal(false);
        updatePayMode(false);
        return true;
    }
}