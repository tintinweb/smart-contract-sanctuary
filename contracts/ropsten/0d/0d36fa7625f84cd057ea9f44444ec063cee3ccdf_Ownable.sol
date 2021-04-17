/**
 *Submitted for verification at Etherscan.io on 2021-04-17
*/

pragma solidity ^0.4.25;

contract Ownable {
    address private owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    // 把当前合约的调用者赋值给owner
    constructor()public{
        owner = msg.sender;
    }

    function CurrentOwner() public view returns (address){
        return owner;
    }

    // 只有智能合约的所有者才能调用的方法
    modifier onlyOwner(){
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
    /**
    * @dev Transfers ownership of the contract to a new account (`newOwner`).
    * Can only be called by the current owner.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract ExTool is Ownable {
    mapping(address => bool) private masterMap;

    event SetMaster(address indexed masterAddr, bool indexed valid);//设置管理员事件
    event BatchTokens(address indexed sender, uint256 indexed count, uint256 indexed successCount);//批量tokens是否全部成功， 未成功的
    constructor()public{
        addMaster(msg.sender);
    }
    //添加owner,添加管理者，无法删除！
    function addMaster(address addr) public onlyOwner {
        require(addr != address(0));
        masterMap[addr] = true;
        emit SetMaster(addr, true);
    }

    function delMaster(address addr) public onlyOwner {
        require(addr != address(0));
        //检查账号是否存在
        if (masterMap[addr]) {
            masterMap[addr] = false;
            emit SetMaster(addr, false);
            //只有之前是管理者，移除时才发送时间
        }
    }

    function isMaster(address addr) public onlyOwner view returns (bool){
        require(addr != address(0));
        return masterMap[addr];
    }

    // 只有合约所有者可以调用
    modifier onlyMaster(){
        require(masterMap[msg.sender], "caller is not the master");
        _;
    }

    //批量转账
    function transferEthsAvg(address[] _tos) payable public onlyMaster returns (bool) {//添加payable,支持在调用方法的时候，value往合约里面传eth，注意该value最终平分发给所有账户
        require(_tos.length > 0, "length is zero");
        require(msg.value > 0, "value is zero");
        uint256 vv = msg.value / _tos.length;
        for (uint256 i = 0; i < _tos.length; i++) {
            _tos[i].transfer(vv);
        }
        return true;
    }

    function transferEths(address[] _tos, uint256[] values) payable public onlyMaster returns (bool) {//添加payable,支持在调用方法的时候，value往合约里面传eth，注意该value最终平分发给所有账户
        require(_tos.length > 0, "length is zero");
        require(msg.value > 0, "value is zero");
        require(_tos.length == values.length);
        //检查金额是否充足
        uint256 total = 0;
        for (uint256 k = 0; k < _tos.length; k++) {
            total += values[k];
        }
        require(msg.value >= total, "value is not enough");
        for (uint256 i = 0; i < _tos.length; i++) {
            _tos[i].transfer(values[i]);
        }
        return true;
    }
    //直接转账
    function transferEth(address _to) payable public onlyMaster returns (bool){
        require(_to != address(0));
        _to.transfer(msg.value);
        return true;
    }
    //将合约中的余额提取出来
    function withdraw(address _to) payable public onlyMaster returns (bool){
        require(_to != address(0));
        _to.transfer(address(this).balance);
        return true;
    }
    //检查当前余额
    function checkBalance() public onlyMaster view returns (uint256) {
        return address(this).balance;
    }

    function() payable public {//添加payable,用于直接往合约地址转eth,如使用metaMask往合约转账
    }
    //销毁合约
    function destroy() public onlyOwner {
        selfdestruct(msg.sender);
    }
    //平均发放，注意，是所有都发送value这个值，而不是value除以length
    function transferTokensAvg(address _from, address tokenAddr, address[] _tos, uint256 value) public onlyMaster returns (bool){
        require(_tos.length > 0);
        uint256 sCount = 0;
        bytes4 id = bytes4(keccak256("transferFrom(address,address,uint256)"));
        for (uint256 i = 0; i < _tos.length; i++) {
            bool tResult = tokenAddr.call(id, _from, _tos[i], value);
            if (tResult) {
                sCount += 1;
            }
        }
        emit BatchTokens(msg.sender, _tos.length, sCount);
        return true;
    }

    function transferTokens(address _from, address tokenAddr, address[] _tos, uint256[] values) public onlyMaster returns (bool){
        require(_tos.length > 0);
        require(values.length == _tos.length);
        bytes4 id = bytes4(keccak256("transferFrom(address,address,uint256)"));
        uint256 sCount = 0;
        for (uint256 i = 0; i < _tos.length; i++) {
            bool tResult = tokenAddr.call(id, _from, _tos[i], values[i]);
            if (tResult) {
                sCount += 1;
            }
        }
        emit BatchTokens(msg.sender, _tos.length, sCount);
        return true;
    }

    function collectTokens(address[] froms, address tokenAddr, address to, uint256[] values) public onlyMaster returns (bool){
        require(froms.length > 0);
        require(froms.length == values.length);
        require(to != address(0));
        bytes4 id = bytes4(keccak256("transferFrom(address,address,uint256)"));
        uint256 sCount = 0;
        for (uint256 i = 0; i < froms.length; i++) {
            bool tResult = tokenAddr.call(id, froms[i], to, values[i]);
            if (tResult) {
                sCount += 1;
            }
        }
        emit BatchTokens(msg.sender, froms.length, sCount);
        return true;
    }

    function collectMultipleTokens(address[] froms, address[] tokenAddrs, address to, uint256[] values) public onlyMaster returns (bool){
        require(froms.length > 0);
        require(to != address(0));
        require(froms.length == values.length);
        require(froms.length == tokenAddrs.length);
        bytes4 id = bytes4(keccak256("transferFrom(address,address,uint256)"));
        uint256 sCount = 0;
        for (uint256 i = 0; i < froms.length; i++) {
            bool tResult = tokenAddrs[i].call(id, froms[i], to, values[i]);
            if (tResult) {
                sCount += 1;
            }
        }
        emit BatchTokens(msg.sender, froms.length, sCount);
        return true;
    }

    //单归集
    function transferTokenFrom(address _from, address tokenAddr, address to, uint256 value) public onlyMaster returns (bool){
        require(_from != address(0));
        require(to != address(0));
        bytes4 id = bytes4(keccak256("transferFrom(address,address,uint256)"));
        return tokenAddr.call(id, _from, to, value);
    }

}