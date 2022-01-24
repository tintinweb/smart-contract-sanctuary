/**
 *Submitted for verification at BscScan.com on 2022-01-23
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address uniswapPair);
}

interface IPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function token0() external view returns (address);

    function token1() external view returns (address);
}

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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
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

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        _move(sender, recipient, amount);
        _afterTokenTransfer(sender, recipient, amount);
    }

    function _move(address sender, address recipient, uint256 amount) internal virtual {
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    receive() external payable {}
}

interface Relationship {
    function relationship(address v1user) external view returns (address parent);
}

contract FalconTokenV2 is ERC20 {
    address public uniswapPair;
    mapping(address => address) public relationship;
    address public marketAddress = 0xF9c1193E443122C5f7dae1957f59D33D2d7c4ee9;
    address public devAddress = 0xc38E1Bda1BDb0A2e4069Ab8BC7A07a3e9a271606;
    address public utmAddress = 0x38B33ec84f6Ad29e430980B98b8C153E9C3a68cd;
    IRouter router;
    mapping(address => bool) excludeFee;
    //    uint256 public airdropAmount = 100;

    uint256 public lastBuyTime;
    address lastBuyUser = devAddress;
    uint256 fomoAmount;
    uint256 devAmount;
    uint256 fomotDuration = 5 * 60;
    uint256 fomoThreshold = 1e16;
    uint256 devThreshold = 1e17;
    address v1address = 0x1bC16275387275eaE7f0C8982c5c6D5cA8345F3d; // main
    //    address v1address = 0xC3ac5872c3F3fFEaC3daB994A455d0A292976b5f; // test
    address _owner;

    event FomoPrize(address user, uint256 amount);
    event DevSwap(address user, uint256 amount);

    constructor() ERC20("Falcon Token Coin V2", "FTCv2") {
        _owner = _msgSender();
               address router_ = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;    // pancake teest
        // address router_ = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        // pancake main
        //        address router_ = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        // uniswap main
        lastBuyTime = block.timestamp;
        relationship[utmAddress] = utmAddress;
        relationship[_owner] = utmAddress;

        excludeFee[_owner] = true;
        excludeFee[router_] = true;
        excludeFee[devAddress] = true;
        excludeFee[utmAddress] = true;
        excludeFee[address(this)] = true;

        initIRouter(router_);

        super._mint(_owner, 2100 * 10 ** 4 * 10 ** 18);
    }
    function initIRouter(address router_) private {
        router = IRouter(router_);
        uniswapPair = IFactory(router.factory()).createPair(address(this), router.WETH());
        excludeFee[uniswapPair] = true;
    }

    bool public poolAdded;

    function _transfer(address from, address to, uint256 amount) internal virtual override {
        if (uniswapPair == to && !poolAdded) {
            require(poolAdded || from == _owner, "please waiting pool liquidity");
            if (from == _owner) poolAdded = true;
        }
        uint256 feeAmount;
        if (uniswapPair == from) {
            _updateRelationship(utmAddress, to);
            if (!excludeFee[to]) {
                feeAmount = handAllFees(from, to, amount);
                //                console.log("feeAmount1: ", feeAmount);
                // fomo 1
                uint256 fee = amount * 1 / 100;
                //                console.log("fee1: ", fee);
                handFomo(to, fee);
                super._move(from, address(this), fee);
                feeAmount += fee;
                //                console.log("feeAmount2: ", feeAmount);

                (uint112 WETHAmount, uint112 TOKENAmount) = getPoolInfo();
                if (WETHAmount * amount / TOKENAmount > fomoThreshold) {
                    lastBuyUser = to;
                }
            }
        } else if (uniswapPair == to) {
            if (!excludeFee[from]) {
                feeAmount = handAllFees(from, from, amount);
                // fomo 1
                uint256 fee = amount * 1 / 100;
                super._move(from, address(this), fee);
                feeAmount += fee;
                //                console.log("fee3: ", fee);
            }
        } else {
            //            if (amount == airdropAmount * 10 ** decimals()) _updateRelationship(from, to);
            //            else _updateRelationship(utmAddress, to);
            _updateRelationship(from, to);
        }
        //        console.log("fee2: ", amount - feeAmount);
        super._transfer(from, to, amount - feeAmount);
    }

    function handAllFees(address from, address user, uint256 amount) private returns (uint256) {
        //        return 0;
        // 营销手续费4
        uint256 fee1 = amount * 4 / 100;
        super._move(from, marketAddress, fee1);

        // 开发1
        uint256 fee2 = amount * 1 / 100;
        super._move(from, address(this), fee2);
        handDev(fee2);

        //        // fomo 1
        //        uint256 fee3 = fee2;
        ////        handFomo(user, fee3);
        //        super._move(from, address(this), fee3);

        // 燃烧2
        uint256 fee4 = amount * 2 / 100;
        super._burn(from, fee4);

        // 分成-p1=2
        uint256 fee5 = fee4;
        address p1 = relationship[user];
        super._move(from, p1, fee5);
        // 分成-p2=1
        uint256 fee6 = fee2;
        address p2 = relationship[p1];
        super._move(from, p2, fee6);
        // 分成-p3=1
        uint256 fee7 = fee2;
        address p3 = relationship[p2];
        super._move(from, p3, fee7);

        return fee1 + fee2 + fee4 + fee5 + fee6 + fee7;
    }

    function handFomo(address user, uint256 amount) private {
        if (block.timestamp - lastBuyTime > fomotDuration) {
            if (fomoAmount > 0) {
                uint256 prize = fomoAmount;
                fomoAmount = 0;
                if (balanceOf(address(this)) - devAmount < prize) prize = balanceOf(address(this)) - devAmount;
                super._move(address(this), lastBuyUser, prize);
                emit FomoPrize(user, prize);
            }
        }
        lastBuyTime = block.timestamp;
        fomoAmount += amount;
    }

    function handDev(uint256 amount) private {
        devAmount += amount;
        uint256 fethbalance = 1E19;
        // 10 ether 为底，超过部分，抽 1/10 给研发
        (uint112 WETHAmount, uint112 TOKENAmount) = getPoolInfo();
        // 奖池累积超过0.1 ether自动卖出到研发钱包
        if (WETHAmount * devAmount / TOKENAmount >= devThreshold) {
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = router.WETH();
            // 超过部分fethbalance，抽 1/10 给研发
            if (WETHAmount * fomoAmount / TOKENAmount > fethbalance) {
                // fethbalance 个eth价值多少token
                uint256 ftokentotal = TOKENAmount * fethbalance / WETHAmount;
                // 基础 ftokentotal + 9/10 额外的token，即为实际token
                fomoAmount = ftokentotal + 9 * (fomoAmount - ftokentotal) / 10;
            }
            devAmount = 0;
            uint256 amountDesire = balanceOf(address(this)) - fomoAmount;
            if (amountDesire > 0) {
                _approve(address(this), address(router), amountDesire);
                router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountDesire, 0, path, devAddress, block.timestamp);
                if (address(this).balance > 0) payable(devAddress).transfer(address(this).balance);
                emit DevSwap(devAddress, amountDesire);
            }
        }
    }

    function getPoolInfo() public view returns (uint112 WETHAmount, uint112 TOKENAmount) {
        (uint112 _reserve0, uint112 _reserve1,) = IPair(uniswapPair).getReserves();
        WETHAmount = _reserve1;
        TOKENAmount = _reserve0;
        if (IPair(uniswapPair).token0() == router.WETH()) {
            WETHAmount = _reserve0;
            TOKENAmount = _reserve1;
        }
    }

    function _updateRelationship(address parent, address child) private {
        if (relationship[child] == address(0)) {
            relationship[child] = parent;
        }
    }


    function handIco(address[] memory ico) private {
        for (uint i=0;i<ico.length;i++) {
            super._move(_owner, ico[i], 50000 * 1E18);
        }
    }
    function v1toV2(address[] memory v1, address[] memory parent, address[] memory children, address[] memory ico) public {
        require(_owner == _msgSender(), "not permitted");
        require(parent.length == children.length, "arr length diff");
        for (uint i = 1; i < parent.length; i++) {
            _updateRelationship(parent[i], children[i]);
        }
        if (ico.length > 0) handIco(ico);
        if (v1.length > 0) {
            IERC20 v1contract = IERC20(v1address);
            for (uint i = 1; i < v1.length; i++) {
                address p = Relationship(v1address).relationship(v1[i]);
                _updateRelationship(p, v1[i]);

                uint256 v1balance = v1contract.balanceOf(v1[i]);
                if (v1balance > 0) super._move(_owner, v1[i], v1balance);
            }
        }
    }
}