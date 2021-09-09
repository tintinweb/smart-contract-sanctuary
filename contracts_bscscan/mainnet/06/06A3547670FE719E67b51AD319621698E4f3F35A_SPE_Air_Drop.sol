/**
 *Submitted for verification at BscScan.com on 2021-09-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function burn(address addr_, uint amount_) external returns (bool);

    function checkHolder() external view returns (uint out);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

library SafeERC20 {

    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {// Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {codehash := extcodehash(account)}
        return (codehash != 0x0 && codehash != accountHash);
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface Main {
    function checkUserInvitor(address addr_) external view returns (address);
}

contract SPE_Air_Drop is Ownable {
    using SafeERC20 for IERC20;
    IERC20 public SPE;
    Main public main;
    uint public burnTotal;
    uint public AirDropAmount ;
    uint[4] public  airDropRate = [10, 90];

    bool public status;
    uint public regTotal;
    uint public regTime;
    uint public regEnd;
    uint public claimTime;
    uint public claimEnd;
    uint public round;
    uint public toClaim;
    uint public claimed;


    struct UserInfo {
        bool reg;
        bool claimed;
    }

    mapping(address => mapping(uint => UserInfo)) public userInfo;
    mapping(address => bool) public Admin;


    event ClaimAirDrop(address indexed sender_, uint indexed amount_, uint indexed round_);

    modifier onlyAdmin(){
        require(Admin[msg.sender], 'not admin');
        _;
    }

    function holder() public view returns (uint out){
        out = SPE.checkHolder();
    }

    function checkRoundTotal() public view returns (uint) {
        uint out;
        if (round == 0) {
            out = 0;
            return out;
        } else {
            out = AirDropAmount * airDropRate[round - 1] / 100;
        }
        return out;
    }

    function openAirDrop(uint round_) public onlyAdmin {
        regTotal = 0;
        status = true;
        regTime = block.timestamp;
        regEnd = block.timestamp + 3600;
        claimTime = block.timestamp + 3600;
        claimEnd = block.timestamp + 7200;
        round = round_;
        toClaim = checkRoundTotal();
        claimed = 0;
    }

    function closeAirDrop() public onlyAdmin {
        status = false;
        if (toClaim > 0 ){
            SPE.transfer(address(0),toClaim);
            toClaim = 0;
        }
    }

    function regAirDrop() public {
        require(SPE.balanceOf(msg.sender) >= 5 * 1e18, 'to low SPE');
        require(main.checkUserInvitor(msg.sender) != address(0), '20');
        require(status, '1');
        require(block.timestamp >= regTime && block.timestamp <= regEnd, '0');
        require(!userInfo[msg.sender][round].reg, '16');
        regTotal += 1;
        userInfo[msg.sender][round].reg = true;
    }

    function claimAirDrop() public {
        require(status, '1');
        require(block.timestamp >= claimTime && block.timestamp <= claimEnd, '0');
        require(userInfo[msg.sender][round].reg, '17');
        require(!userInfo[msg.sender][round].claimed,'18');
        uint tempAmount = (AirDropAmount * airDropRate[round - 1] / 100) / regTotal;
        SPE.transfer(msg.sender, tempAmount);
        userInfo[msg.sender][round].claimed = true;
        userInfo[msg.sender][round].reg = false;
        toClaim -= tempAmount;
        claimed += tempAmount;
        emit ClaimAirDrop(msg.sender, tempAmount, round);
    }

    function checkToClaimAir() public view returns (uint) {
        uint out = toClaim;
        return out;
    }

    function checkClaimedAir() public view returns (uint) {
        uint out = claimed;
        return out;

    }

    function setAdamin(address addr_) public onlyOwner {
        Admin[addr_] = true;
    }

    function setSpe(address addr_) public onlyOwner {
        SPE = IERC20(addr_);
    }

    function setMain(address addr_) public onlyOwner {
        main = Main(addr_);
        setAdamin(addr_);
        Admin[addr_] = true;

    }
    function setAmount(uint com_) public onlyOwner{
        AirDropAmount = com_ * 1e18;
    }


}