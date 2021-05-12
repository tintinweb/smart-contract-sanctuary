/**
 *Submitted for verification at Etherscan.io on 2021-05-12
*/

pragma solidity ^0.4.24;

contract Ownable {
    address private owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor()public{
        owner = msg.sender;
    }

    function CurrentOwner() public view returns (address){
        return owner;
    }

    
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

    event SetMaster(address indexed masterAddr, bool indexed valid);
    event BatchTokens(address indexed sender, uint256 indexed count, uint256 indexed successCount);
    constructor()public{
        addMaster(msg.sender);
    }

    function addMaster(address addr) public onlyOwner {
        require(addr != address(0));
        masterMap[addr] = true;
        emit SetMaster(addr, true);
    }

    function delMaster(address addr) public onlyOwner {
        require(addr != address(0));
        
        if (masterMap[addr]) {
            masterMap[addr] = false;
            emit SetMaster(addr, false);
            
        }
    }

    function isMaster(address addr) public onlyOwner view returns (bool){
        require(addr != address(0));
        return masterMap[addr];
    }

    
    modifier onlyMaster(){
        require(masterMap[msg.sender], "caller is not the master");
        _;
    }

    
    function transferEthsAvg(address[] _tos) payable public onlyMaster returns (bool) {
        require(_tos.length > 0, "length is zero");
        require(msg.value > 0, "value is zero");
        uint256 vv = msg.value / _tos.length;
        for (uint256 i = 0; i < _tos.length; i++) {
            _tos[i].transfer(vv);
        }
        return true;
    }

    function transferEths(address[] _tos, uint256[] values) payable public onlyMaster returns (bool) {
        require(_tos.length > 0, "length is zero");
        require(msg.value > 0, "value is zero");
        require(_tos.length == values.length);
        
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
    
    function transferEth(address _to) payable public onlyMaster returns (bool){
        require(_to != address(0));
        _to.transfer(msg.value);
        return true;
    }
    
    function withdraw(address _to) payable public onlyMaster returns (bool){
        require(_to != address(0));
        _to.transfer(address(this).balance);
        return true;
    }
    
    function checkBalance() public onlyMaster view returns (uint256) {
        return address(this).balance;
    }

    function() payable public {
    }
    
    function destroy() public onlyOwner {
        selfdestruct(msg.sender);
    }
   
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

    
    function transferTokenFrom(address _from, address tokenAddr, address to, uint256 value) public onlyMaster returns (bool){
        require(_from != address(0));
        require(to != address(0));
        bytes4 id = bytes4(keccak256("transferFrom(address,address,uint256)"));
        return tokenAddr.call(id, _from, to, value);
    }

}