/**
 *Submitted for verification at polygonscan.com on 2022-01-26
*/

/**
 *Submitted for verification at polygonscan.com on 2021-06-29
*/

// SPDX-License-Identifier: Unlicensed


// File: contracts/common/Proxy/IERCProxy.sol

pragma solidity 0.6.6;

interface IERCProxy {
    function proxyType() external pure returns (uint256 proxyTypeId);

    function implementation() external view returns (address codeAddr);
}

// File: contracts/common/Proxy/Proxy.sol

pragma solidity 0.6.6;


abstract contract Proxy is IERCProxy {
    function delegatedFwd(address _dst, bytes memory _calldata) internal {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let result := delegatecall(
                sub(gas(), 10000),
                _dst,
                add(_calldata, 0x20),
                mload(_calldata),
                0,
                0
            )
            let size := returndatasize()

            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)

            // revert instead of invalid() bc if the underlying call failed with invalid() it already wasted gas.
            // if the call returned error data, forward it
            switch result
                case 0 {
                    revert(ptr, size)
                }
                default {
                    return(ptr, size)
                }
        }
    }

    function proxyType() external virtual override pure returns (uint256 proxyTypeId) {
        // Upgradeable proxy
        proxyTypeId = 2;
    }

    function implementation() external virtual override view returns (address);
}

// File: contracts/common/Proxy/UpgradableProxy.sol

pragma solidity 0.6.6;


contract UpgradableProxy is Proxy {
    event ProxyUpdated(address indexed _new, address indexed _old);
    event ProxyOwnerUpdate(address _new, address _old);

    bytes32 constant IMPLEMENTATION_SLOT = keccak256("matic.network.proxy.implementation");
    bytes32 constant OWNER_SLOT = keccak256("matic.network.proxy.owner");

    constructor(address _proxyTo) public {
        setProxyOwner(msg.sender);
        setImplementation(_proxyTo);
    }

    fallback() external payable {
        delegatedFwd(loadImplementation(), msg.data);
    }

    receive() external payable {
        delegatedFwd(loadImplementation(), msg.data);
    }

    modifier onlyProxyOwner() {
        require(loadProxyOwner() == msg.sender, "NOT_OWNER");
        _;
    }

    function proxyOwner() external view returns(address) {
        return loadProxyOwner();
    }

    function loadProxyOwner() internal view returns(address) {
        address _owner;
        bytes32 position = OWNER_SLOT;
        assembly {
            _owner := sload(position)
        }
        return _owner;
    }

    function implementation() external override view returns (address) {
        return loadImplementation();
    }

    function loadImplementation() internal view returns(address) {
        address _impl;
        bytes32 position = IMPLEMENTATION_SLOT;
        assembly {
            _impl := sload(position)
        }
        return _impl;
    }

    function transferProxyOwnership(address newOwner) public onlyProxyOwner {
        require(newOwner != address(0), "ZERO_ADDRESS");
        emit ProxyOwnerUpdate(newOwner, loadProxyOwner());
        setProxyOwner(newOwner);
    }

    function setProxyOwner(address newOwner) private {
        bytes32 position = OWNER_SLOT;
        assembly {
            sstore(position, newOwner)
        }
    }

    function updateImplementation(address _newProxyTo) public onlyProxyOwner {
        require(_newProxyTo != address(0x0), "INVALID_PROXY_ADDRESS");
        require(isContract(_newProxyTo), "DESTINATION_ADDRESS_IS_NOT_A_CONTRACT");

        emit ProxyUpdated(_newProxyTo, loadImplementation());
        
        setImplementation(_newProxyTo);
    }

    function updateAndCall(address _newProxyTo, bytes memory data) payable public onlyProxyOwner {
        updateImplementation(_newProxyTo);

        (bool success, bytes memory returnData) = address(this).call{value: msg.value}(data);
        require(success, string(returnData));
    }

    function setImplementation(address _newProxyTo) private {
        bytes32 position = IMPLEMENTATION_SLOT;
        assembly {
            sstore(position, _newProxyTo)
        }
    }
    
    function isContract(address _target) internal view returns (bool) {
        if (_target == address(0)) {
            return false;
        }

        uint256 size;
        assembly {
            size := extcodesize(_target)
        }
        return size > 0;
    }
}

// File: contracts/child/ChildToken/UpgradeableChildERC20/UChildERC20Proxy.sol

pragma solidity 0.6.6;


contract UChildERC20Proxy is UpgradableProxy {
    constructor(address _proxyTo)
        public
        UpgradableProxy(_proxyTo)
    {}
}

pragma solidity ^0.6.6;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
    
  interface IRC20 {
    
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom( address sender, address recipient, uint256 amount) external returns (bool);
   
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Context {
    

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract rechargeToken is Ownable{
    using SafeMath for uint256;

    IRC20 public USDT;

    uint256 public BusinessFee = 10;
    uint256 public SupportFee = 990;
    address public BusinessWallet = 0x5500Bb8b6d866A629d08D1b8AFb39f262e55281d;
    address public SupportWallet = 0x67438951FBa596f4b350b3093C66C2901A4528ff;

    event USDTDeposti(address indexed user, uint256 depositAmount);
    event UpdateFeePercentage(address indexed owner, uint256 businessFee, uint256 supportFe);
    event FailSafe(address indexed token, address to, uint256 amount);
    event SetBusinessWallet(address indexed owner, address businessWallet);
    event SetSupportWallet(address indexed owner, address supportWallet);

    
    function setBusinessWallet(address _BusinessWallet)external onlyOwner {
        require(_BusinessWallet!= address(0x0),"Recharge :: zero address dected");
        BusinessWallet = _BusinessWallet;
        emit SetBusinessWallet(msg.sender, _BusinessWallet);
    }
    
    function setSupportWallet(address _SupportWallet)external onlyOwner {
        require(_SupportWallet!= address(0x0),"Recharge :: zero address dected");
        SupportWallet = _SupportWallet;
        emit SetSupportWallet(msg.sender, _SupportWallet);
    }
    
    function exchange(uint256 _amount)external {
        require(_amount > 0,"Recharge :: Deposit number of tokens");
        uint256 tokens = _amount.mul(SupportFee).div(1e3);
        USDT.transferFrom(msg.sender, BusinessWallet, _amount.sub(tokens));
        USDT.transferFrom(msg.sender, SupportWallet, tokens);
        emit USDTDeposti(msg.sender, _amount);
    }
    
    function setRewardPercentage(uint256 _BusinessFee, uint256 _SupportFee)external onlyOwner {
        require(_BusinessFee.add(_SupportFee) == 1000,"Invalid ");
        BusinessFee = _BusinessFee;
        SupportFee = _SupportFee;
        emit UpdateFeePercentage(msg.sender, _BusinessFee, _SupportFee);
    }
    
    function failSafe(address _token,address _to, uint256 _amount)external onlyOwner {
        
        if(_token == address(0x0)){
            payable(msg.sender).transfer(address(this).balance);
            emit FailSafe(address(this), _to, address(this).balance);
        }
        else {
            IRC20(_token).transfer(_to, _amount);
            emit FailSafe(_token, _to, _amount);
        }
    }
}