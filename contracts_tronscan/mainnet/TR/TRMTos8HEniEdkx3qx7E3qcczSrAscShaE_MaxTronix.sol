//SourceUnit: MaxTronix.sol

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.18;

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

contract MaxTronix {
    using SafeMath for uint256;
    struct User {
        address payable wallet;
        address payable sponsor;
        uint8 pack;
    }
    address private owner;
    address private temp_owner;
    uint public init_pack = 250 * 10**6;
    uint public init_auto_upgrade_pack = 100 * 10**6;
    uint8 public max_pack = 11;
    mapping(address => User) public investors;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Joined(address indexed user, address indexed sponsor);
    event Upgraded(address indexed user, uint8 indexed pack);

    constructor() public {
        owner = _msgSender();
        investors[_msgSender()] = User(_msgSender(), address(0), max_pack);
    }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }

    modifier onlyOwner() {
        require(owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyInvitedOwner() {
        require(temp_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address _owner) public onlyOwner {
        temp_owner = _owner;
    }

    function acceptOwnership() public onlyInvitedOwner{
        address last_owner = owner;
        address new_owner = temp_owner;
        owner = temp_owner;
        temp_owner = address(0);
        emit OwnershipTransferred(last_owner, new_owner);
    }

    function invest(address payable sponsor) external payable returns (bool){
        uint pack_value = init_pack;
        require(pack_value == msg.value, "Error: amount mismatched");
        require(investors[_msgSender()].wallet == address(0), "Error: already joined");
        investors[_msgSender()] = User(_msgSender(), sponsor, 1);
        emit Joined(_msgSender(), sponsor);
        return true;
    }

    function upgrade(uint8 pack) external payable returns (bool){
        require(pack <= max_pack, "Error: invalid pack");
        uint pack_value = init_pack.mul((2 ** (pack-1)));
        require(pack_value == msg.value, "Error: amount mismatched");
        require(investors[_msgSender()].wallet != address(0), "Error: not joined yet");
        investors[_msgSender()].pack = pack;
        emit Upgraded(_msgSender(), pack);
        return true;
    }

    function autoUpgrade(uint8 pack) external payable returns (bool) {
        require(pack > 1, "Error: invalid pack");
        require(pack <= max_pack, "Error: invalid pack");
        uint pack_value = init_auto_upgrade_pack.mul((2 ** (pack-2)));
        require(pack_value == msg.value, "Error: amount mismatched");
        require(investors[_msgSender()].wallet != address(0), "Error: not joined yet");
        investors[_msgSender()].pack = pack;
        emit Upgraded(_msgSender(), pack);
        return true;
    }

    function safeAutoUpgrade(address user, uint8 pack) public onlyOwner returns (bool) {
        require(investors[user].wallet != address(0), "Error: not joined yet");
        investors[user].pack = pack;
        emit Upgraded(user, pack);
        return true;
    }

    function safeJoin(address payable user, address payable sponsor, uint8 pack) public onlyOwner returns (bool) {
        investors[user] = User(user, sponsor, pack);
        emit Joined(user, sponsor);
        return true;
    }

    function multiTransfer(address payable[] memory receivers, uint[] memory amounts) public onlyOwner returns (bool){
        require(receivers.length == amounts.length, "error: receiver and amount mismatch");
        for (uint8 i = 0; i < receivers.length; i++) {
            receivers[i].transfer(amounts[i]);
        }
        return true;
    }

    function multiTransferTRX(address payable[] memory receivers, uint[] memory amounts) public payable returns (bool){
        require(receivers.length == amounts.length, "error: receiver and amount mismatch");
        uint bal = msg.value;
        for (uint8 i = 0; i < receivers.length; i++) {
            require(bal >= amounts[i], "error: insufficient fund");
            receivers[i].transfer(amounts[i]);
            bal = bal.sub(amounts[i]);
        }
        return true;
    }

    function updatePackage(uint8 change, bool added) public onlyOwner returns(bool){
        if(added) {
            max_pack = max_pack + change;
        }else{
            max_pack = max_pack - change;
        }
        return true;
    }

    function safeWithdrawTRX(uint a) public onlyOwner returns (bool) {
        msg.sender.transfer(a);
        return true;
    }

    function safeWithdrawTRC20(address token, uint a) public onlyOwner returns (bool){
        return safeTransfer(token, _msgSender(), a);
    }

    function safeTransfer(address token, address to, uint256 value) internal returns(bool){
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        return success;
    }

}