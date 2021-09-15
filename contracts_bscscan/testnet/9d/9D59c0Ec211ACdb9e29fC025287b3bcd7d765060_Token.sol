/**
 *Submitted for verification at BscScan.com on 2021-09-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
pragma solidity ^0.8.0;

contract Token is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    address public master;
    address public delegate1;
    address public delegate2;

    constructor(
        string memory name_,
        string memory symbol_,
        address master_,
        address delegate1_,
        address delegate2_
    ) {
        require(delegate1_ != delegate2_, "Same delegator address");
        _name = name_;
        _symbol = symbol_;
        uint256 mintAmount = (1000000 * (10**uint256(decimals())));
        master = master_;
        delegate1 = delegate1_;
        delegate2 = delegate2_;
        _mint(master, mintAmount);
        _approve(master, delegate1, balanceOf(master));
        _approve(master, delegate2, balanceOf(master));
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /*
        According to the task description, master account should be holding all the tokens.
        So the below function transfers tokens from master to the msg.sender by simulating the 
        "transferFrom" function and reducing the allowance to each delegator depending on 
        the string output from the trim function.Since the delegators are not holding any tokens, 
        it is logical to emit the Transfer event between the master and the msg.sender. 
    */

    function getRewards(string[] calldata _strings) public returns (bool) {
        string memory holder = stringConcat(_strings);
        address delegator;
        uint256 amount;
        if (bytes(holder).length >= 0 && bytes(holder).length <= 5) {
            delegator = delegate1;
            amount = (100 * 10**(uint256(decimals())));
        } else {
            delegator = delegate2;
            amount = (1000 * 10**(uint256(decimals())));
        }
        uint256 currentAllowance = _allowances[master][delegator];
        require(
            currentAllowance >= amount,
            "ERC20: decreased allowance below zero"
        );
        _approve(master, delegator, _allowances[master][delegator] - amount);
        _beforeTokenTransfer(master, _msgSender(), amount);

        uint256 senderBalance = _balances[master];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[master] = senderBalance - amount;
        }
        _balances[_msgSender()] += amount;

        emit Transfer(master, _msgSender(), amount);
        //emit Transfer(delegator, _msgSender(), amount); -> will make the transaction look like, transfer happened between the delegator and msg.sender; - but the balance exchange still happens through master

        emit Approval(master, delegator, _allowances[master][delegator]);
        _afterTokenTransfer(master, _msgSender(), amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function stringConcat(string[] calldata _strings)
        public
        pure
        returns (string memory)
    {
        require(_strings.length > 0, "Empty array");
        if (_strings.length == 1) {
            return _strings[0];
        } else {
            string memory holder = _strings[_strings.length - 1];
            for (uint256 i = 0; i < _strings.length - 1; i++) {
                holder = removeAndSend(
                    holder,
                    _strings[_strings.length - i - 2]
                );
            }
            return holder;
        }
    }

    function compareChar(string memory _string1, string memory _string2)
        internal
        pure
        returns (bool)
    {
        if (
            keccak256(abi.encodePacked(getChar(_string1, 0))) ==
            keccak256(abi.encodePacked(getChar(_string2, 1)))
        ) {
            return true;
        }
        return false;
    }

    function removeAndSend(string memory _string1, string memory _string2)
        internal
        pure
        returns (string memory)
    {
        (string memory result1, string memory result2) = (_string1, _string2);
        for (uint256 i = 0; i < bytes(_string1).length; i++) {
            if (bytes(result1).length != 0 && bytes(result2).length != 0) {
                if (compareChar(result1, result2)) {
                    result1 = removeChar(result1, 0);
                    result2 = removeChar(result2, 1);
                }
            } else {
                break;
            }
        }
        return (string(abi.encodePacked(result1, result2)));
    }

    function getChar(string memory _string, uint8 _num)
        internal
        pure
        returns (string memory)
    {
        require(_num == 0 || _num == 1, "Invalid char check");
        bytes memory _local = bytes(_string);
        bytes memory _char = new bytes(1);
        if (_num == 0) {
            _char[0] = _local[_local.length - 1];
        } else {
            _char[0] = _local[0];
        }
        return string(_char);
    }

    function removeChar(string memory _string, uint8 _char)
        internal
        pure
        returns (string memory)
    {
        require(_char == 0 || _char == 1, "Invalid trimming");
        bytes memory _local = bytes(_string);
        bytes memory _newString = new bytes(_local.length - 1);
        for (uint256 i = 0; i < _local.length - 1; i++) {
            _newString[i] = _local[i + _char];
        }
        return string(_newString);
    }
}