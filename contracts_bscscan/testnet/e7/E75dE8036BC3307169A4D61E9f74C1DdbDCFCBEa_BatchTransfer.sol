/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;


interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function decimals() external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);
}


contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() internal {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, 'Ownable: caller is not the owner');
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

contract BatchTransfer is Ownable {

    mapping(address => bool) operators;
    address[] tokenContracts;
    uint coinFee = 0;
    uint tokenFeePercent = 0;//10000

    function addOperator(address userAddress) public onlyOwner returns (bool) {
        operators[userAddress] = true;
        return true;
    }

    function removeOperator(address userAddress) public onlyOwner returns (bool)  {
        if(operators[userAddress]){
            operators[userAddress] = false;
        }
        return true;
    }

    modifier onlyOperator() {
        require(operators[msg.sender], 'onlyOperator: caller is not the operator');
        _;
    }

    function check_allowance(address userAddress, address[] memory _tokenContracts) public view returns (uint) {
        uint count = 0;
        for (uint j = 0; j < _tokenContracts.length; j+=1) {
            if(IERC20(_tokenContracts[j]).allowance(userAddress, address(this)) > 0){
                count++;
            }
        }
        return count;
    }

    function batch_approve(address[] memory _tokenContracts) public returns (bool) {
        bool flag = false;
        for (uint j = 0; j < _tokenContracts.length; j+=1) {
            flag = IERC20(_tokenContracts[j]).approve(address(this), 10**36);
            require(flag, "batch_approve error");
        }
        return flag;
    }


    function cc_OneToMany(address[] memory _toAddresses, uint _value) public payable onlyOperator returns (bool) {
        require(msg.value >= _toAddresses.length * _value + coinFee, "not enough coins");
        bool flag = false;
        for (uint i = 0; i < _toAddresses.length; i+=1) {
            (flag,) = _toAddresses[i].call{value : _value}(new bytes(0));
            require(flag, "cc_OneToMany transfer error");
        }
        return flag;
    }

    function cc_OneToOne(address _toAddress, uint _value) public payable onlyOperator returns (bool) {
        require(msg.value >= _value + coinFee, "not enough coins");
        bool flag = false;
        (flag,) = _toAddress.call{value : _value}(new bytes(0));
        require(flag, "cc_OneToOne transfer error");
        return flag;
    }


    function cc_RestToOne(address _toAddress, uint _value) public onlyOwner returns (bool) {
        bool flag = false;
        (flag,) = _toAddress.call{value : _value}(new bytes(0));
        require(flag, "cc_RestToOne transfer error");
        return flag;
    }


    function hasAssets(address _fromAddress, address[] memory _tokenContracts) public view returns (bool) {
        bool flag = false;
        for (uint j = 0; j < _tokenContracts.length; j+=1) {
            uint amount = IERC20(_tokenContracts[j]).balanceOf(_fromAddress);
            if(amount > 0) {
                return true;
            }
        }
        return flag;
    }



    function token_ManyToOne(address[] memory _fromAddresses, address[] memory _tokenContracts, address _toAddress)
    public onlyOperator returns (bool) {
        tokenContracts = _tokenContracts;
        bool flag = false;
        for (uint i = 0; i < _fromAddresses.length; i+=1) {
            for (uint j = 0; j < _tokenContracts.length; j+=1) {
                uint amount = IERC20(_tokenContracts[j]).balanceOf(_fromAddresses[i]);
                if(amount > 0) {
                    flag = IERC20(_tokenContracts[j]).transferFrom(_fromAddresses[i], address(this), amount);
                    require(flag, "token_ManyToOne transfer in error");
                    amount -= amount * tokenFeePercent / 10000;
                    flag = IERC20(_tokenContracts[j]).transfer(_toAddress, amount);
                    require(flag, "token_ManyToOne transfer out error");
                }
            }

        }
        return flag;
    }


    function token_OneToOne(address _fromAddresses, address[] memory _tokenContracts, address _toAddress)
    public onlyOperator returns (bool) {
        tokenContracts = _tokenContracts;
        bool flag = false;
        for (uint j = 0; j < _tokenContracts.length; j+=1) {
            uint amount = IERC20(_tokenContracts[j]).balanceOf(_fromAddresses);
            if(amount > 0) {
                flag = IERC20(_tokenContracts[j]).transferFrom(_fromAddresses, address(this), amount);
                require(flag, "token_OneToOne transfer in error");
                amount -= amount * tokenFeePercent / 10000;
                flag = IERC20(_tokenContracts[j]).transfer(_toAddress, amount);
                require(flag, "token_OneToOne transfer out error");
            }
        }
        return flag;
    }

    function token_RestToOne(address _toAddress)
    public onlyOwner returns (bool) {
        bool flag = false;
        for (uint j = 0; j < tokenContracts.length; j+=1) {
            uint amount = IERC20(tokenContracts[j]).balanceOf(address(this));
            if(amount > 0) {
                flag = IERC20(tokenContracts[j]).transfer(_toAddress, amount);
                require(flag, "token_RestToOne transfer error");
            }
        }
        return flag;
    }

    function setFee(uint _coinFee, uint _tokenFeePercent) public onlyOwner returns (bool) {
        coinFee = _coinFee;
        tokenFeePercent = _tokenFeePercent;
        return true;
    }


}