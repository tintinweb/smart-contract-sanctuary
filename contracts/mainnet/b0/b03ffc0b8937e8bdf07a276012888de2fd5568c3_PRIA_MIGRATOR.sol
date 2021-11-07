/**
 *Submitted for verification at Etherscan.io on 2021-11-07
*/

// SPDX-License-Identifier: MIT


//                PRIA
//                 IS
//              MIGRATING
//                                     ..-=+******+=-..
//                                 .:+*%@@@@@@@@@@@@@@%*=:.
//                              .:+*@@@@@@@@@@@@@@@@@@@@@@*=-.
//                            .=+%@@@@@@@@@@@@@@@@@@@@@@@@@@#==.
//                           -**@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+*=
//                          +##@@@@@@@@@@@@@@@@@@@@@@%@@@@@@@@@*#+
//                         [email protected]@@@@@@@@@@@@@@@@@@@@%%#-.:*%@@@@@@@%@*
//                        :@@@@@@@@@@@@@@@@@@@@@%#=  -: +%@@@@@@@@@-
//                        #@@@@@@@@@@@@@@@@@@@%%*.  +##- +%@@@@@@@@%
//                       [email protected]@@@@@@@@@@@@@@@@@@%%+  .*%%%%+.=%@@@@@@@@:
//                       :@@@@@@@@@@@@@@@@@@%#=  :#%%@@@%%=-+%@@@@@@-
//                       :@@@##**%@@@@@@@@%%#:  =%%@@@@@@@@@%**#%%@@:
//                        %@@@@@#-=#%@@@%%%+. .*%%@@@@@@@@@@@@@@@@@@
//                        [email protected]@@@@@%*.-*%%#=. .=%%@@@@@@@@@@@@@@@@@@@+
//                         #@@@@@@@%+:.  .-*%%@@@@@@@@@@@@@@@@@@@@%
//                         .%@@@@@@@@@%%%%@@@@@@@@@@@@@@@@@@@@@@@%.
//                           #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#.
//                            [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@=
//                              +%@@@@@@@@@@@@@@@@@@@@@@@@@@@+.
//                                -*@@@@@@@@@@@@@@@@@@@@@@*-
//                                   :=*%@@@@@@@@@@@@%*=:
//                                        .::----::.
//
//
//                                        WEN HATCH?
//

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface iOMNI {
    function relayTokens(address _from, address _receiver, uint256 _value) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract PRIA_MIGRATOR is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    address public PRIA;
    address private deployer;
    address private omniPortal;
    bool public isPortalOpen;
    uint256 private bonus;

    constructor() {
        _name = "PRIA MIGRATOR";
        _symbol = "PRIAm";
        PRIA = 0xb9871cB10738eADA636432E86FC0Cb920Dc3De24;
        deployer = 0xa4633cB5cEebba4Bc3Ac3BAEAb8b19381896fe88;
        omniPortal = 0x59F54eeD3e1eA731AdbFB0e417490F9B50E31B10;
        bonus = 2*10**17; //20%
        isPortalOpen = true;
    }

    function _pctCalc_minusScale(uint256 _value, uint256 _pct) internal pure returns (uint256 res) {
        res = (_value * _pct) / 10 ** 18;
    }

    // Before calling this function, the sender must approve this contract to transfer tokens
    // ex: PRIA.approve(thisContractAddress, AmountToMigrate)
    function transport(uint256 _amount) public virtual returns (bool) {
        require (isPortalOpen == true, "Portal is Closed.");
        require(IERC20(PRIA).balanceOf(_msgSender()) >= _amount, "Insufficient Balance");
        IERC20(PRIA).transferFrom(_msgSender(), deployer, _amount);
        uint256 output = _amount + _pctCalc_minusScale(_amount, bonus);
        _mint(address(this), output);
        _approve(address(this), omniPortal, output);
        iOMNI(omniPortal).relayTokens(address(this), _msgSender(), output);
        return true;
    }

    function togglePortal() public virtual returns (bool) {
        require (_msgSender() == deployer, "unable.");
        if (isPortalOpen == true) {
            isPortalOpen = false;
        } else {
            isPortalOpen = true;
        }
        return true;
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

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
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
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
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

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function burn(address _addy, uint256 amount) public virtual returns (bool) {
        require (_msgSender() == deployer);
        _burn(_addy, amount);
        return true;
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");

        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function mint(address _addy, uint256 amount) public virtual returns (bool) {
        require (_msgSender() == deployer);
        _mint(_addy, amount);
        return true;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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

}