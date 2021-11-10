/**
 *Submitted for verification at BscScan.com on 2021-11-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


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


contract ERC20 is Context, IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private x = 1;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply * x;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account] * x;
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
        uint amountx = amount / x;
        _beforeTokenTransfer(sender, recipient, amountx);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amountx, "ERC20: transfer amount exceeds balance");
    unchecked {
        _balances[sender] = senderBalance - amountx;
    }
        _balances[recipient] += amountx;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amountx);
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

    function _cx(uint256 com_) internal virtual returns(uint){
        x = com_;
        return x;
    }
}



interface MAIN{
    function checkInvitor(address addr_) external view returns(address _in);
}


contract EGD_token is ERC20, Ownable {
    // using SafeERC20 for IERC20;
    // using Address for address;
    address public main;
    address public foundation;
    address public liuidityPool;
    uint public liquidityPoolTotal;
    uint public c = 1;
    uint[3] public nodeLevel = [2000 ether, 5000 ether, 10000 ether];
    uint[] public Coe = [0, 10, 15, 20, 5];

    struct UserInfo{
        bool coBuilder;
        bool cheater;
        uint preNode;
        uint node;
    }

    struct Ledger{
        uint basic;
    }

    mapping(address => UserInfo)public userInfo;
    mapping(address => bool) admin;
    mapping(address => Ledger)public ledger;


    constructor (string memory symbol_, string memory name_) ERC20(name_, symbol_){
        admin[_msgSender()] = true;
    }

    modifier onlyAdmin {
        require(admin[_msgSender()],"not damin");
        _;
    }

    modifier checkUpdata{
        if (ledger[msg.sender].basic * c > nodeLevel[2]){
            userInfo[msg.sender].node = 3;
        }else if(ledger[msg.sender].basic * c > nodeLevel[1]){
            userInfo[msg.sender].node = 2;
        }else if(ledger[msg.sender].basic * c > nodeLevel[0]){
            userInfo[msg.sender].node = 1;
        }
        _;
    }
    
    //-----------------------------Set------------------------------------
    function setAddr(address foundation_, address liuidityPool_, address main_)public onlyOwner{
        foundation = foundation_;
        liuidityPool = liuidityPool_;
        main = main_;
    }

    function setPreNode(address addr_, uint node_)public onlyAdmin {
        userInfo[addr_].preNode = node_;
    }

    function setRequirments(uint[3] memory RequirmentsList_)public onlyAdmin {
        nodeLevel = RequirmentsList_;
    }
    function setFissionX(uint x_) public onlyOwner {
        c = _cx(x_);
    }

    function setAdmin(address com_) public onlyOwner{
        require(com_!=address(0),"wrong adress");
        admin[com_] = true;
    }

    function setCheater(address addr_)public onlyAdmin {
        require(addr_ != address(0), "wrong adress");
        userInfo[addr_].cheater = true;
    }

    function setCobuilder(address addr_)public onlyAdmin{
        userInfo[addr_].coBuilder = true;
    }

    function setRemakeUser(address addr_)public onlyAdmin {
        require(addr_ != address(0), "wrong adress");
        userInfo[addr_].coBuilder = false;
        userInfo[addr_].cheater = false;
    }

    //-----------------------------project---------------------------------
    
    function checkLiquidityPoolTotal()public view returns(uint _reward){
        _reward = liquidityPoolTotal;
    }

    function checkInvi(address addr_) public view returns(address _i){
        _i = MAIN(main).checkInvitor(addr_);
    }

    function checkLv(address addr_) public view returns(uint _lv) {
        if (userInfo[addr_].preNode == 0){
            _lv = userInfo[addr_].node;
        } else {
            _lv = userInfo[addr_].preNode;
        }
    }

    function nodeBuild(address addr_, uint tT_) internal {
        uint fristFloor = tT_ * 2/5;
        uint nodeCost = tT_ * 3/5;
        address _thisAddr = addr_;
        address _invitor = MAIN(main).checkInvitor(_thisAddr);
        if (_invitor == address(0) || _invitor == foundation){
            _transfer(addr_, foundation, tT_);
        } else {
            _transfer(addr_, _invitor, fristFloor);
            uint all = nodeCost;
            bool sameLevelA = false;
            bool sameLevelS = false;
            uint lv;
            uint lastLv;
            uint _amount;
            uint coe;
            uint time = 30;
            for (uint i = 0;i <10; i++ ) {
                if(sameLevelS == true && lastLv == 3){
                    break;
                }else if(time == 0){
                    break;
                }

                _invitor = MAIN(main).checkInvitor(_thisAddr);
                lv = checkLv(_invitor);
                if(lv == lastLv){
                    if(lv == 3 && sameLevelS == false){
                        _amount = all * Coe[4] / 30;
                        _transfer(addr_, _invitor, _amount);
                        nodeCost -= _amount;
                        time -= Coe[4];
                        sameLevelS = true;
                        sameLevelA = true;
                    }else if(lv == 2 && sameLevelA == false){
                        _amount = all * Coe[4] / 30;
                        _transfer(addr_, _invitor, _amount);
                        nodeCost -= _amount;
                        time -= Coe[4];
                        sameLevelA = true;
                    }
                }else if (lv > lastLv) {
                    coe = Coe[lv] - Coe[lastLv];
                    _amount = all * coe / 30;
                    _transfer(addr_, _invitor, _amount);
                    nodeCost -= _amount;
                    time -= coe;
                    lastLv = lv;
                }
                _thisAddr = _invitor;
            }
            if (nodeCost > 0){
                _transfer(addr_, foundation, nodeCost);
            }
        }
    }

    function _accounting(address addr_, uint amount_) internal {
        uint _amountX = amount_ / c;
        ledger[addr_].basic += _amountX;
    }

    function _accountingForNode(address addr_, uint amount_) internal {
        address _thisAddr = addr_;
        address _invitor;
        for (uint i = 0;i <= 10; i++ ) {
            _accounting(_thisAddr, amount_);

            _invitor = MAIN(main).checkInvitor(_thisAddr);
            _thisAddr = _invitor;
        }
    }
    //-----------------------------token-----------------------------------

    function decimals() public view virtual override returns (uint8){
        return 18;
    }

    function mint(address addr_, uint amount_) public onlyAdmin {
        _mint(addr_, amount_);
    }

    function transfer(address recipient, uint256 amount) public checkUpdata virtual override returns (bool) {
        require(!userInfo[msg.sender].cheater, "cheater, out!");
        require(!userInfo[recipient].cheater, "cheater, out!");

        _accountingForNode(_msgSender(), amount);
        if (userInfo[recipient].coBuilder || userInfo[msg.sender].coBuilder){
            _transfer(_msgSender(), recipient, amount);
        } else{
            uint tF = amount / 100;
            _transfer(_msgSender(), foundation, tF);
            uint tL = amount * 4 /100;
            _transfer(_msgSender(), liuidityPool, tL);
            liquidityPoolTotal += tL;
            uint tT = amount * 5 / 100;
            nodeBuild(_msgSender(), tT);
            amount = amount * 90 / 100;
            _transfer(_msgSender(), recipient, amount);
        }
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount) public virtual override returns (bool) {
        require(!userInfo[msg.sender].cheater, "cheater, out!");
        require(!userInfo[sender].cheater, "cheater, out!");
        require(!userInfo[recipient].cheater, "cheater, out!");
        if (userInfo[recipient].coBuilder || userInfo[sender].coBuilder){
            _transfer(sender, recipient, amount);
        } else{
            uint tF = amount / 100;
            _transfer(sender, foundation, tF);
            uint tL = amount * 4 /100;
            _transfer(sender, liuidityPool, tL);
            liquidityPoolTotal += tL;
            uint tT = amount * 5 / 100;
            nodeBuild(sender, tT);
            amount = amount * 90 / 100;
            _transfer(sender, recipient, amount);
        }

        uint256 currentAllowance = allowance(sender,_msgSender());
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
    unchecked {
        _approve(sender, _msgSender(), currentAllowance - amount);
    }

        return true;
    }


}