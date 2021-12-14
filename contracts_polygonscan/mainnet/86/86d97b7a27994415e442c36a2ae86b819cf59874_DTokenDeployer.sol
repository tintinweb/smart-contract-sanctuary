// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "./interface/IDC2CDeployer.sol";
import "./DToken.sol";

contract DTokenDeployer is IDC2CDeployer{
    function develop(address factory, address token) external returns (address){
        return address(new DToken{salt: keccak256(abi.encode(factory, token))}(factory, token));
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.9;

interface IERC20 {

    //stand erc20 method ------- start

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    //returns the amount of tokens in existence.
    function totalSupply() external view returns (uint256);

    //returns the amount of tokens owned by `account`.
    function balanceOf(address account) external view returns (uint256);

    //returns the remaining number of tokens that `spender` will be allowed to spend on behalf of `owner` through {transferFrom}. This is zero by default.
    function allowance(address owner, address spender) external view returns (uint256);

    //moves `amount` tokens from the caller's account to `recipient`.
    //returns a boolean value indicating whether the operation succeeded.
    function transfer(address recipient, uint256 amount) external returns (bool);

    //sets `amount` as the allowance of `spender` over the caller's tokens.
    //returns a boolean value indicating whether the operation succeeded.
    function approve(address spender, uint256 amount) external returns (bool);

    //moves `amount` tokens from `payer` to `recipient` using the allowance mechanism. `amount` is then deducted from the caller's allowance.
    //returns a boolean value indicating whether the operation succeeded.
    function transferFrom(
        address payer,
        address recipient,
        uint256 amount
    ) external returns (bool);

    //stand erc20 method ------- end

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity  ^0.8.9;

interface IDC2CFactory {

    struct Config{
        address org;
        uint256 fee; // feeRatio = fee / 1000
        uint256 returnPer; //percent value of fee will return to payer and stockholder and inviter
        uint256 oldPer; //percent value of returnPer will return to old stockholder
        uint256 inviterPer;//percent of returnPer token will be send to inviter
        uint256 topNum;
    }

    event DC2CPoolCreated(address token);

    //deploy DC2CPool
    function createPool(
        address token//external token,eg: USDT
    ) external returns (bool);

    function setConfig(address org, uint256 fee,  uint256 returnPer, uint256 oldPer,  uint256 inviterPer, uint256 topNum) external;
    function getConfig() external view returns (Config memory);
    function getDC2CPool(address token) external view returns (address);
    function getDToken(address token) external view returns (address);

    function tokenSize() external view returns (uint size);
    //return token list[from,to)
    function getTokens(uint from, uint to) external view returns (address[] memory);

    function getInviter(address account) external view returns (address);
    function setInviter(address account, address inviter) external returns (bool);

}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.9;

interface IDC2CDeployer {
    function develop(address factory, address token) external returns (address);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.9;

import "./interface/IERC20.sol";
import "./interface/IDC2CFactory.sol";
contract DToken is IERC20{

    string private constant PREFIX="d";
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _asset;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    address public factory;
    address public token;

    constructor(address _factory, address _token) {
        factory = _factory;
        token = _token;
        _name = string(abi.encodePacked(PREFIX, IERC20(_token).name()));
        _symbol = string(abi.encodePacked(PREFIX, IERC20(_token).symbol()));
        _decimals = IERC20(_token).decimals();
    }

    modifier onlyPool() {
        require(IDC2CFactory(factory).getDC2CPool(token) == msg.sender, "DToken: caller is not the pool");
        _;
    }

    //stand erc20 method ------- start
    
   //returns the name of the token.
    function name() public view returns (string memory) {
        return _name;
    }
    //returns the symbol of the token, usually a shorter version of the
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    //returns the number of decimals used to get its user representation. For example, if `decimals` equals `2`, a balance of `505` tokens should be displayed to a user as `5.05` (`505 / 10 ** 2`).
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }


    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function transferFrom( address payer, address recipient, uint256 amount ) public override returns (bool) {
        _transfer(payer, recipient, amount);

        uint256 currentAllowance = _allowances[payer][msg.sender];
        require(currentAllowance >= amount, "DToken: transfer amount exceeds allowance");
        unchecked {
            _approve(payer, msg.sender, currentAllowance - amount);
        }
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "DToken: decreased allowance below zero");
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function _transfer( address payer, address recipient, uint256 amount ) internal {
        require(payer != address(0), "DToken: transfer from the zero address");
        require(recipient != address(0), "DToken: transfer to the zero address");

        uint256 payerBalance = _balances[payer];
        require(payerBalance >= amount, "DToken: transfer amount exceeds balance");
        unchecked {
            _balances[payer] = payerBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(payer, recipient, amount);
    }
    function _approve( address owner, address spender, uint256 amount ) internal {
        require(owner != address(0), "DToken: approve from the zero address");
        require(spender != address(0), "DToken: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    //stand erc20 method ------- end


    //compute mint token will return how many dToken
    function tryMint(uint256 fee) external view returns (uint256 amount) {
        uint256 addSupply;
        if(_asset != 0){
            addSupply = fee * _totalSupply / _asset;
        } else {
            addSupply = fee * 1000;
        }

        uint256 addOrg = 0;
        if(IDC2CFactory(factory).getConfig().returnPer < 100) {
            addOrg = addSupply * (100 - IDC2CFactory(factory).getConfig().returnPer) / 100;
        }

        //half will be dispatched to stockholder ;
        uint256 addReturn = (addSupply - addOrg) * IDC2CFactory(factory).getConfig().oldPer / 100;
        uint256 addInviter = addReturn * IDC2CFactory(factory).getConfig().inviterPer / 100;

        amount = addReturn - addInviter;
    }

    //mint dToken
    function mint(address to, uint256 fee) public onlyPool returns (uint256 amount){
        address inviter = IDC2CFactory(factory).getInviter(to);
        if(to == inviter || inviter == address(0)){inviter = IDC2CFactory(factory).getConfig().org;}

        uint256 asset = _balanceOf(address(this));
        require(_asset + fee <= asset, "DToken: ASSET_INVALID");

        uint256 addSupply;
        if(_asset != 0){
            addSupply = fee * _totalSupply / (asset - fee);
        } else {
            addSupply = fee * 1000;
        }

        uint256 addOrg = 0;
        if(IDC2CFactory(factory).getConfig().returnPer < 100) {
            addOrg = addSupply * (100 - IDC2CFactory(factory).getConfig().returnPer) / 100;
            _balances[IDC2CFactory(factory).getConfig().org] += addOrg;
            emit Transfer(address(0), IDC2CFactory(factory).getConfig().org, addOrg);
        }

        //half will be dispatched to stockholder ;
        uint256 addReturn = (addSupply - addOrg) * IDC2CFactory(factory).getConfig().oldPer / 100;
        uint256 addInviter = addReturn * IDC2CFactory(factory).getConfig().inviterPer / 100;

        amount = addReturn - addInviter;
        _balances[to] += amount;
        _balances[inviter] += addInviter;

        _asset = asset;
        _totalSupply += addReturn + addOrg;

        emit Transfer(address(0), to, amount);
        emit Transfer(address(0), inviter, addInviter);
    }
    //compute burn dToken will return how many asset amount
    function tryBurn(uint256 amount) external view returns (uint256){
        if(_totalSupply < 1) {
            return 0;
        }
        return amount * _asset/_totalSupply;
    }

    //burn dToken and withdraw asset token
    function burn(uint256 amount) external returns (bool){
        uint256 accountBalance = _balances[msg.sender];
        require(amount > 0, "DToken: AMOUNT_TOO_SMALL");
        require(accountBalance >= amount, "DToken: BALANCE_NO_ENOUGH");

        unchecked {
            _balances[msg.sender] = accountBalance - amount;
        }

        uint256 subAsset = amount * _asset/_totalSupply; // _totalSupply not possible zero when accountBalance >= amount > 0
        _asset -= subAsset;
        _totalSupply -= amount;

        _safeTransfer(msg.sender, subAsset);

        emit Transfer(msg.sender, address(0), amount);

        return true;
    }

    function _safeTransfer(address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), ' DToken: TRANSFER_FAILED');
    }

    function _balanceOf(address account) internal view returns (uint256) {
        // bytes4(keccak256(bytes('balanceOf(address)')));
        (bool success, bytes memory data) =
        token.staticcall(abi.encodeWithSelector(0x70a08231,account));
        require(success && data.length >= 32, " DToken: BALANCE_INVALID");
        return abi.decode(data, (uint256));
    }
}