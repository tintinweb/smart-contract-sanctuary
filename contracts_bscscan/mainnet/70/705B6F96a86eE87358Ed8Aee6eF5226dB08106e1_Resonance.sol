/**
 *Submitted for verification at BscScan.com on 2021-09-17
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
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
    function userInfo(address addr_) external view returns (uint, uint, uint, uint, uint, address, uint, uint, uint, uint, uint, uint);
}

contract Resonance is Ownable {
    using SafeERC20 for IERC20;
    IERC20 public U;
    IERC20 public BCL;
    Main public main;
    uint public constant normalQouta = 50 * 1e18;
    uint public normalPool;
    uint public whitePool;
    uint public SP = 25;
    uint public amountToUp = 10500 * 1e9;
    address public wallet;
    uint public price = 40 * 1e17;
    uint public  onceAmount = 50 * 1e18;
    uint public totalLeft = 105000 * 1e9;
    uint[5] public vipAmount = [50, 100, 150, 200, 300];


    event NormalBuy (address indexed sender_, uint cost_, uint claimed_);
    event WhiteBuy (address indexed sender_, uint cost_, uint claimed_);


    struct UserInfo {
        uint normalClaimed;
        uint whiteClaimed;
        bool isSet;
        uint setAmount;
    }

    mapping(address => UserInfo) public userInfo;
    function setOnceAmount(uint amount_) public onlyOwner {
        onceAmount = amount_;
    }

    function setAddress(address BCL_, address USD_, address mainContract_, address wallet_) public onlyOwner {
        U = IERC20(USD_);
        BCL = IERC20(BCL_);
        main = Main(mainContract_);
        wallet = wallet_;
    }


    function checkUserInfo(address addr_) public view returns (uint level, uint referD, uint referN, uint Power){
        (,,,,,,,level,referD,referN,,Power) = main.userInfo(addr_);
    }

    function coutingUserQouta(address addr_) public view returns (uint out){
        uint L;
        uint RD;
        uint RN;
        uint NP;
        (L, RD, RN, NP) = checkUserInfo(addr_);
        if (L > 0) {
            out += vipAmount[L - 1] * 1e18;
        }
        if (RD >= 30 && RN >= 500 && NP >= 15000000 * 1e18) {
            out += 1000 * 1e18;
        } else if (RD >= 20 && RN >= 200 && NP >= 10000000 * 1e18) {
            out += 800 * 1e18;
        } else if (RD >= 15 && RN >= 100 && NP >= 5000000 * 1e18) {
            out += 600 * 1e18;
        } else if (RD >= 10 && RN >= 50 && NP >= 2000000 * 1e18) {
            out += 400 * 1e18;
        } else if (RD >= 5 && RN >= 200 && NP >= 1000000 * 1e18) {
            out += 200 * 1e18;
        }
        if (userInfo[msg.sender].isSet) {
            out = userInfo[msg.sender].setAmount;
        }

    }

    function normalBuy(uint Uamount_) public {
        require(Uamount_ <= onceAmount,'over amount');
        uint _temp = Uamount_ * 1e9 / price;
        uint _BCLAmount;
        uint _cost;
        require(userInfo[msg.sender].normalClaimed + Uamount_ <= normalQouta,'out qouta');
        require(_temp <= normalPool, 'over limit');
        if (_temp > amountToUp) {
            if (_temp > totalLeft) {
                _BCLAmount = totalLeft;
                _cost = _BCLAmount * price * (100 + SP) / 100 / 1e9;
                normalPool -= _BCLAmount ;
                totalLeft -= _BCLAmount;
                userInfo[msg.sender].normalClaimed += Uamount_;
                BCL.safeTransfer(msg.sender, _BCLAmount);
                U.safeTransferFrom(msg.sender, address(this), _cost);
            } else {
                uint _amount1 = amountToUp;
                uint leftU = Uamount_ - (_amount1 * price / 1e9);
                uint _amount2 = leftU * 1e9 / (price + 1e17);
                amountToUp = 10500 * 1e9 - _amount2;
                _BCLAmount = _amount2 + _amount1;
                _cost = ((_amount1 * price) + (_amount2 * (price + 1e17))) * (100 + SP) / 100 / 1e9;
                price += 1e17;
                normalPool -= _BCLAmount;
                totalLeft -= _BCLAmount;
                userInfo[msg.sender].normalClaimed += Uamount_;
                BCL.safeTransfer(msg.sender, _BCLAmount);
                U.safeTransferFrom(msg.sender, address(this), _cost);
            }
        } else {
            amountToUp -= _temp;
            userInfo[msg.sender].normalClaimed += Uamount_;
            _BCLAmount = _temp;
            normalPool -= _BCLAmount;
            totalLeft -= _BCLAmount;
            _cost = Uamount_ * (100 + SP) / 100;
            BCL.safeTransfer(msg.sender, _BCLAmount);
            U.safeTransferFrom(msg.sender, wallet, _cost);
        }
        emit NormalBuy(msg.sender, _cost, _BCLAmount);

    }

    function whiteBuy(uint Uamount_) public {
        require(Uamount_ <= onceAmount,'over amount');
        uint _temp = Uamount_ * 1e9 / price;
        uint _BCLAmount;
        uint _cost;
        uint userQuota;
        userQuota = coutingUserQouta(msg.sender);
        require(userInfo[msg.sender].whiteClaimed + Uamount_ <= userQuota,'out qouta');
        require(_temp <= whitePool, 'over limit');
        if (_temp > amountToUp) {
            if (_temp > totalLeft) {
                _BCLAmount = totalLeft;
                _cost = _BCLAmount * price * (100 + SP) / 100 / 1e9;
                whitePool -= _BCLAmount ;
                totalLeft -= _BCLAmount;
                userInfo[msg.sender].whiteClaimed += Uamount_;
                BCL.safeTransfer(msg.sender, _BCLAmount);
                U.safeTransferFrom(msg.sender, wallet, _cost);
            } else {
                uint _amount1 = amountToUp;
                uint leftU = Uamount_ - (_amount1 * price / 1e9);
                uint _amount2 = leftU * 1e9 / (price + 1e17);
                amountToUp = 10500 * 1e9 - _amount2;
                _BCLAmount = _amount2 + _amount1;
                _cost = ((_amount1 * price) + (_amount2 * (price + 1e17))) * (100 + SP) / 100 / 1e9;
                price += 1e17;
                whitePool -= _BCLAmount;
                totalLeft -= _BCLAmount;
                userInfo[msg.sender].whiteClaimed += Uamount_;
                BCL.safeTransfer(msg.sender, _BCLAmount);
                U.safeTransferFrom(msg.sender, wallet, _cost);
            }
        } else {
            amountToUp -= _temp;
            userInfo[msg.sender].whiteClaimed += Uamount_;
            _BCLAmount = _temp;
            whitePool -= _BCLAmount;
            totalLeft -= _BCLAmount;
            _cost = Uamount_ * (100 + SP) / 100;
            BCL.safeTransfer(msg.sender, _BCLAmount);
            U.safeTransferFrom(msg.sender, wallet, _cost);
        }
        emit WhiteBuy(msg.sender, _cost, _BCLAmount);
    }

    function coutingWhiteCost(uint Uamount_) public view returns (uint cost, uint bclAmount){
        require(Uamount_ <= onceAmount,'over amount');
        uint _temp = Uamount_ * 1e9 / price;
        uint userQuota;
        userQuota = coutingUserQouta(msg.sender);
        require(userInfo[msg.sender].whiteClaimed + Uamount_ <= userQuota,'out qouta');
        require(_temp <= whitePool, 'over limit');
        if (_temp > amountToUp) {
            if (_temp > totalLeft) {
                bclAmount = totalLeft;
                cost = bclAmount * price * (100 + SP) / 100 / 1e9;
            } else {
                uint _amount1 = amountToUp;
                uint leftU = Uamount_ - (_amount1 * price / 1e9);
                uint _amount2 = leftU * 1e9 / (price + 1e17);
                bclAmount = _amount2 + _amount1;
                cost = ((_amount1 * price) + (_amount2 * (price + 1e17))) * (100 + SP) / 100 / 1e9;
            }
        } else {
            bclAmount = _temp;
            cost = Uamount_ * (100 + SP) / 100;

        }

    }

    function coutingNormalCost(uint Uamount_) public view returns (uint cost, uint bclAmount){
        require(Uamount_ <= onceAmount,'over amount');
        uint _temp = Uamount_ * 1e9 / price;
        require(userInfo[msg.sender].normalClaimed + Uamount_ <= normalQouta,'out qouta');
        require(_temp <= normalPool, 'over limit');
        if (_temp > amountToUp) {
            if (_temp > totalLeft) {
                bclAmount = totalLeft;
                cost = bclAmount * price * (100 + SP) / 100 / 1e9;
            } else {
                uint _amount1 = amountToUp;
                uint leftU = Uamount_ - (_amount1 * price / 1e9);
                uint _amount2 = leftU * 1e9 / (price + 1e17);
                bclAmount = _amount2 + _amount1;
                cost = ((_amount1 * price) + (_amount2 * (price + 1e17))) * (100 + SP) / 100 / 1e9;
            }
        } else {
            bclAmount = _temp;
            cost = Uamount_ * (100 + SP) / 100;

        }
    }

    function start(uint normal_, uint white_) public onlyOwner {
        whitePool += white_;
        normalPool += normal_;
        BCL.safeTransferFrom(msg.sender, address(this), normal_ + white_);
    }

    function setWhiteAmount(address addr_, uint amount_, bool com_) public onlyOwner {
        userInfo[addr_].isSet = com_;
        userInfo[addr_].setAmount = amount_;
    }

    function safePull(address addr_) public onlyOwner {
        BCL.transfer(addr_, BCL.balanceOf(address(this)));
    }
    
    function getUserLeftNormalQouta(address addr_) public view returns(uint out){
        out = normalQouta - userInfo[addr_].normalClaimed;
    }

    function getUserLeftWthiteQouta(address addr_) public view returns(uint out){
        if (coutingUserQouta(addr_) < userInfo[addr_].whiteClaimed){
            return out = 0;
        }
        out = coutingUserQouta(addr_) - userInfo[addr_].whiteClaimed;
    }
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