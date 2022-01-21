// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./TRC20Interface.sol";

contract CrazyForest {
    // 剩余时间
    function remainTime() public view returns (uint256) {
    }

    // 购买树苗
    function buyTree(uint256 index, uint256 num) external {
    }

    // 提取分红
    function dividendTake() external returns (uint256) {
    }

    // 提取奖池收益
     function poolTake() external {
    }

    function activate(address superUser) external {
    }

    function orderNum() external view returns (uint32) {
    }

    function treeOwner(uint256 idx) external view returns (address) {
    }

    function dividendOf(address account) external view returns (uint256) {
    }

    function poolOf(address account) external view returns (uint256) {
    }

}

contract TreeBuy {
    mapping(address => uint256) private _admins;
    TRC20Interface internal usdt;
    CrazyForest internal cf;
    uint256 time = 10;
    modifier onlyAdmin() {
        require(_admins[msg.sender] == 1, "Only admin can change items");
        _;
    }

    constructor(address _usdt, address _cf) {
        _admins[msg.sender] = 1;
        usdt = TRC20Interface(_usdt);
        cf = CrazyForest(_cf);
    }

    function isLast() external view returns (bool) {
        return cf.treeOwner(cf.orderNum() - 1) == address(this);
    }

    function remainTime() external view returns (uint256) {
        return cf.remainTime();
    }

    function buyTree() external onlyAdmin {
        require(cf.remainTime() < time, "Not time!");
        cf.buyTree(0, 1);
    }

    function buyTree1() external onlyAdmin {
        require(cf.remainTime() < time, "Not time!");
        require(cf.treeOwner(cf.orderNum() - 1) != address(this), "Already buy!");
        cf.buyTree(0, 1);
    }

    function buyTree2(uint256 num) external onlyAdmin {
        require(cf.remainTime() < time, "Not time!");
        cf.buyTree(0, num);
    }

    function dividendTake() external {
        cf.dividendTake();
    }

    function poolTake() external {
        cf.poolTake();
    }

    function remainTake(address account, uint256 amount) external onlyAdmin {
        usdt.transfer(account, amount);
    }
    
    function activate(address superUser) external onlyAdmin {
        cf.activate(superUser);
    }

    function approve() external onlyAdmin {
        usdt.approve(address(cf), 100000000000000);
    }

    function setCF(address _cf) external onlyAdmin {
        cf = CrazyForest(_cf);
    }

    function setAdmin(address admin) external onlyAdmin {
        _admins[admin] = 1;
    }

    function setTime(uint256 _time) external onlyAdmin {
        time = _time;
    }

    function setUSDT(address _usdt) external onlyAdmin {
        usdt = TRC20Interface(_usdt);
    }

    function dividendOf() external view returns (uint256) {
       return cf.dividendOf(address(this));
    }

    function poolOf() external view returns (uint256) {
        return cf.poolOf(address(this));
    }
}