/**
 *Submitted for verification at polygonscan.com on 2021-08-20
*/

pragma solidity ^0.5.5;


interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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

contract Context {
    
    
    constructor () internal { }
    

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}


contract ERC20Airdropper {
    using SafeMath for uint256;


     function transfer(address _token, address payable _referral, address[] calldata _addresses, uint256[] calldata _values) payable external returns (bool) {
        require(_addresses.length == _values.length, "Address array and values array must be same length");

        

        uint256 totalTokensSent;
        for (uint i = 0; i < _addresses.length; i += 1) {
            require(_addresses[i] != address(0), "Address invalid");
            require(_values[i] > 0, "Value invalid");

            IERC20(_token).transferFrom(msg.sender, _addresses[i], _values[i]);
            totalTokensSent = totalTokensSent.add(_values[i]);
        }

    emit Transfer(_token, msg.sender, _addresses.length, totalTokensSent);

        return true;
    }

    function moveEther(address payable _account) external returns (bool) {
        uint256 contractBalance = address(this).balance;
        _account.transfer(contractBalance);
        emit EtherMoved(msg.sender, _account, contractBalance);
        return true;
    }

    
    function moveTokens(address _token, address _account) external returns (bool) {
        uint256 contractTokenBalance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_account, contractTokenBalance);
        emit TokensMoved(msg.sender, _account, contractTokenBalance);
        return true;
    }

    event Transfer(
        address indexed _token,
        address indexed _caller,
        uint256 _recipientCount,
        uint256 _totalTokensSent
    );
    event EtherMoved(
        address indexed _caller,
        address indexed _to,
        uint256 _amount
    );

    event TokensMoved(
        address indexed _caller,
        address indexed _to,
        uint256 _amount
    );

}