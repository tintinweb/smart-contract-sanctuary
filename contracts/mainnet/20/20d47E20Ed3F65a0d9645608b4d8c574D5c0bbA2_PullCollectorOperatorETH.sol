/**
 *Submitted for verification at Etherscan.io on 2022-01-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

pragma solidity ^0.6.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

pragma solidity ^0.6.0;

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() private view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}

pragma solidity ^0.6.6;

contract PullCollectorOperatorETH is
    Ownable // контракт сборщик на майнет сети
{
    address[] private users; // список всех юзеров кто вложил
    mapping(address => uint256) public balances; // меп юзеров и их вложенных балансов
    address payable public distributor; //адрес  кошелька распределителя
    address public admin;
    event NewInvestor(address investor);

    constructor() public {
        distributor = msg.sender;
        admin = msg.sender;
    }

    function set_admin(address _admin) public onlyOwner {
        admin = _admin;
    }

    function set_new_distributor(address payable _distributor)
        public
        onlyOwner
    {
        // ставим нового распределителя
        distributor = _distributor;
    }

    function get_users(uint256 _id) public view returns (address) {
        // получение юзера по его айди
        return users[_id];
    }

    function get_count_users() public view returns (uint256) {
        // получение общего количества вложившихся юзеров через контракт
        return users.length;
    }

    function get_en_balances(address _user) public view returns (uint256) {
        // получить сколько вложил юзер по его адресу
        return balances[_user];
    }

    function invest() external payable {
        // метод инвестирования средств в текущий котракт
        if (balances[msg.sender] == 0) {
            emit NewInvestor(msg.sender);
        }
        balances[msg.sender] += msg.value;
        users.push(msg.sender);
    }

    function transfer_native(uint256 _amount) public payable {
        //метод отсылки нативки на кошель распределителя
        require(msg.sender == admin, "Sign adress not Admin");
        distributor.transfer(_amount);
    }
}