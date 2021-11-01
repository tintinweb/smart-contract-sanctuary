// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import './Ownable.sol';
import './Context.sol';
import './IBEP20.sol';
import './SafeMath.sol';
import './OUPToken.sol';
import './Getprice.sol';
// import './Math.sol';

contract UPTOKEN is Context, IBEP20, Ownable , PriceConsumerV3 {
    using SafeMath for uint256;

    // using Math for uint256;

    event WithdrawtoOwnerEvent(address indexed Owneraddress, uint256 amount);

    OUPToken public worker; // = OUPToken(address(0xe5141e959A568a842668E8410294af46091eEfcb));
    uint256 GNumber = 161803;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply = 10000 * 10 ** 18;

    string private _name = "OVER";
    string private _symbol = "OVER";
    uint8 private _decimals = 18;

    uint256 public cap = 0;
    uint256 private _maxcap = 200000 * 10 ** 18;
    uint256 public maxcap = _maxcap;
    bool private isPresaleEnd = false;
    uint8 private _presalePrice = 1 ;
    uint8 public presalePrice = _presalePrice;


    constructor(OUPToken _worker) public {
        worker = _worker;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function getBalanceWorkerToken(address addr) public view returns(uint256){
        return worker.balanceOf(addr);
    }
    
    function doWork(address _from, uint256 _amount) internal {
        worker.burn(_from, _amount);
    }

    function mintWorker(address _to, uint256 _amount) internal {
        worker.mint(_to, _amount);
    }



    function getOwner() external override view returns (address) {
        return owner();
    }

    function name() public override view returns (string memory) {
        return _name;
    }

    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(getBalanceWorkerToken(_msgSender()) > (gasleft() * tx.gasprice) ,"You Have not enough worker Token" );
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom (address sender, address recipient, uint256 amount) public override returns (bool) {
        require(getBalanceWorkerToken(_msgSender()) > (gasleft() * tx.gasprice) ,"You Have not enough worker Token" );
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, 'BEP20: transfer amount exceeds allowance')
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, 'BEP20: decreased allowance below zero'));
        return true;
    }

    function mint(uint256 amount) public onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
        return true;
    }

    function _transfer (address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), 'BEP20: transfer from the zero address');
        require(recipient != address(0), 'BEP20: transfer to the zero address');

        _balances[sender] = _balances[sender].sub(amount, 'BEP20: transfer amount exceeds balance');
        _balances[recipient] = _balances[recipient].add(amount);
        doWork(sender, (gasleft() * tx.gasprice));
        emit Transfer(sender, recipient, amount);
    }


    function _mint(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: mint to the zero address');
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);

        mintWorker(_msgSender(), amount * GNumber);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: burn from the zero address');

        _balances[account] = _balances[account].sub(amount, 'BEP20: burn amount exceeds balance');
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve (address owner, address spender, uint256 amount) internal {
        require(owner != address(0), 'BEP20: approve from the zero address');
        require(spender != address(0), 'BEP20: approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, 'BEP20: burn amount exceeds allowance'));
    }


    function buypresale() payable public returns(bool){
        require(cap <= _maxcap && !isPresaleEnd ,"Presale is ended");
        return _buypresale(msg.value);
    }
  
    function _buypresale(uint256 _payamount) private returns(bool){
        uint256 _msgValue = _payamount;
        uint256 _price_msgValue = PriceAmount(_msgValue);
        uint256 _token = _price_msgValue.div(_presalePrice).mul(10);
        cap = cap.add(_msgValue);
        _mint(_msgSender(),_token);
        return true;
    }

    function PriceAmount(uint _amount) public view returns(uint256){
        return (_amount.mul(uint256(getLatestPrice())));
    }

    function PreSale_END() external onlyOwner returns(bool){
        return _PreSale_END();
    }

    function _PreSale_END() private returns(bool){
        isPresaleEnd = true;        
        return isPresaleEnd;
    }


    function WithdrawToOwner() external onlyOwner {
        _WithdrawToOwner();
    }

    function _WithdrawToOwner() private {
        payable(owner()).transfer(address(this).balance);
        emit WithdrawtoOwnerEvent(_msgSender(), address(this).balance);
    }

    function WithdrawERC20(IBEP20 token) external onlyOwner returns(bool){
        require(token.transfer(msg.sender, token.balanceOf(address(this))), "Transfer failed");
        return true;
    }

}