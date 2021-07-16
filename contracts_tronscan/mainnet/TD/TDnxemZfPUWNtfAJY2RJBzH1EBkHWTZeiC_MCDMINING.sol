//SourceUnit: MCDMINING.sol

pragma solidity >=0.4.24;

interface IERC20 {

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) external returns
    (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns
    (uint256 remaining);
}

contract MCDMINING {


    function safeTransfer(address token, address to, uint256 value) internal {
        // bytes4 id = bytes4(keccak256("transfer(address,uint256)"));
        // bool success = token.call(id, to, value);
        // require(success, 'TransferHelper: TRANSFER_FAILED');
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }


    mapping(address => bool) private masterMap;
    //percent/denominator = 30%
    uint256 percent = 30;
    uint256 denominator = 100;

    address payable feeAddr = address(0xd84d6Ba9F86A493CdaD873283C013A0E9ac6a2e5);


    constructor()public{
        //随便添加默认管理员
        _addMaster(0x371151580c49cf13Eddd1499A826B5837298c821);
    }
    // 只有合约所有者可以调用
    modifier onlyMaster(){
        require(masterMap[msg.sender], "caller is not the master");
        _;
    }
    //添加owner,添加管理者，无法删除！
    function addMaster(address addr) public onlyMaster {
        _addMaster(addr);
    }

    function _addMaster(address _addr) internal {
        require(_addr != address(0));
        masterMap[_addr] = true;
    }

    //提eth/trx
    function withdrawTrx(address payable _to, uint256 _v) public onlyMaster {
        require(address(this).balance >= _v, "not enough");
        _to.transfer(_v);
    }

    //提token
    function withdrawToken(address _token, address _to, uint256 _v) public onlyMaster {
        IERC20 erc = IERC20(_token);
        require(erc.balanceOf(address(this)) >= _v, " not enough");
        safeTransfer(_token, _to, _v);
    }

    event DepositTrx(address indexed _from, uint256 _value);
    event DepositToken(address indexed _from, uint256 _value);

    //充代币，需要先授权
    function depositToken(address token, uint256 value) public payable  {
        safeTransferFrom(token, msg.sender, address(this), value);
        safeTransfer(token, feeAddr, value * percent / denominator);
        emit DepositToken(msg.sender, msg.value);
    }
    //充trx/eht，直接转
    function depositTrx() public payable {
        emit DepositTrx(msg.sender, msg.value);
        feeAddr.transfer(msg.value * percent / denominator);
    }
}