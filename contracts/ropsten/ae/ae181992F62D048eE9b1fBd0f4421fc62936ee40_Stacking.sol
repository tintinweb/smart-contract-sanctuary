/**
 *Submitted for verification at Etherscan.io on 2021-10-23
*/

pragma solidity =0.6.6;

interface IUniswapV2ERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface myIERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    
    function _mint(address to, uint value) external;
    function _burn(address from, uint value) external;

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface myIERC202 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    
    function _mint(address to, uint value) external;

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}


library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
}

library TransferHelper {
    function _safeApprove(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x104e81ff, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: _APPROVE_FAILED');
    }
    
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        /*(bool success, bytes memory data) = */
        (bool success,) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success, 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

contract Stacking
{
    using SafeMath for uint;
    address private immutable hb;
    address private immutable xhb;
    
    constructor() public {
        hb = address(0xbedbA1be044F42E16D9F058813bd7bFAE407AA54);
        xhb = address(0xA74c44b16ad510417c52CDB62b4c7c28C7f2A9E5);
    }
    
    struct UserInfo {
        address userAddress;
        uint256 buriedTokens;
        uint256 longTokens;
        uint256 startBlockNumber;
    }
    
    UserInfo[] public userInfo;
    
    function getUserInfoLength() public view returns (uint256) {
        return userInfo.length;
    }
    
    function getUserInfo(uint index) public view returns (address, uint256, uint256)
    {
        return (userInfo[index].userAddress, userInfo[index].buriedTokens, userInfo[index].longTokens);
    }
    
    mapping(address => uint) public userIndexes;
    
    function buryTokens(uint amountBONE) public {
        if(amountBONE == 0) {
            return;
        }
        
        IERC20(hb).transferFrom(msg.sender, address(this), amountBONE);

        uint amountBONEtoBury = amountBONE / 3;
        uint amountBONEtoLong = amountBONE.sub(amountBONEtoBury);
        
        uint index = userIndexes[msg.sender];
        
        if (index < 1)
        {
            userInfo.push(UserInfo({
                userAddress: msg.sender,
                buriedTokens: amountBONEtoBury,
                longTokens: amountBONEtoLong,
                startBlockNumber: block.number
            }));
            
            userIndexes[msg.sender] = getUserInfoLength();
        }
        else
        {
            userInfo[index-1].buriedTokens += amountBONEtoBury;
            userInfo[index-1].longTokens += amountBONEtoLong;
        }
        
        // mint stacking tokens to user
        myIERC20(xhb)._mint(msg.sender, amountBONE);
    }
    
    function withdrawTokens(uint amountBONE) public
    {
        uint index = userIndexes[msg.sender];
        uint amountToWithdraw = amountBONE.div(1000).mul(997);
        // uint amountLeft = amountBONE.sub(amountToWithdraw);
        userInfo[index-1].buriedTokens -= amountBONE;
        myIERC20(xhb)._burn(msg.sender, amountBONE);
        IERC20(hb).transfer(msg.sender, amountToWithdraw);
    }
    
    function giveTokensToUser(address user, uint amount) public
    {
        uint index = userIndexes[user];
        userInfo[index-1].buriedTokens += amount;
        myIERC20(xhb)._mint(user, amount);
        myIERC202(hb)._mint(address(this), amount);
    }
}