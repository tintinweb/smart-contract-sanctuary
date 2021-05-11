/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

pragma solidity 0.8.1;

contract SwapAggregator{
    // 支持交易的代币合约地址
    mapping(address => bool) public contractAddress;

    address public owner;
    address public lasagnaFactory;
    // 接收代理费地址, ropsten:0x741c9a4Deb5A5c583d62e18f127a17C18BbddA38
    address public agencyFeePool;
    address public uniswapV2Router02 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    // ropsten: 0xc778417E063141139Fce010982780140Aa0cD5Ab
    address public WETH;    

    bytes4 public SELECTOR_WITHDRAW = bytes4(keccak256(bytes('withdraw(uint256')));
    bytes4 public SELECTOR_TRANSFER = bytes4(keccak256(bytes('transfer(address,uint256)')));
    bytes4 public SELECTOR_TRANSFER_FROM = bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    bytes4 public SELECTOR_SWAP_EXACTTOEKN_FOR_TOKENS = bytes4(keccak256(bytes('swapExactTokensForTokens(uint256,uint256,address[],address,uint256)')));
    bytes4 public SELECTOR_SWAP_TOKENS_FOR_EXACTTOKEN = bytes4(keccak256(bytes('swapTokensForExactTokens(uint256,uint256,address[],address,uint256)')));
    bytes4 public SELECTOR_SWAP_EXACTTOEKN_FOR_ETH = bytes4(keccak256(bytes('swapExactTokensForETH(uint256,uint256,address[],address,uint256)')));
    bytes4 public SELECTOR_SWAP_TOKENS_FOR_EXACTETH = bytes4(keccak256(bytes('swapTokensForExactETH(uint256,uint256,address[],address,uint256)')));

    constructor(address _lasagnaFactory,address _agencyFeePool,address _WETH,address _USDT,address _USDC,address _CNHC){
        owner = msg.sender;
        lasagnaFactory = _lasagnaFactory;
        agencyFeePool = _agencyFeePool;
        WETH = _WETH;
        addErc(_USDT); // ropsten: USDT 0xfA8caA9cF80250e0835c4e6D982671C97f262E52
        addErc(_USDC); // ropsten: USDC 0xfDD26b7CfE425E42083bEA36E11250DE25BeDA9b
        addErc(_CNHC); // ropsten: CNHC 0x41BAcAd6Eb73C3Ad4adCb071b909D6aB17931183
        addErc(WETH); // ropsten: WETH
    }
    /*
        添加支持的代币
    */
    function addErc(address _contractAddress) public onlyOwner{
        require(_contractAddress != address(0),"contractAddress cannot be zero");
        require(contractAddress[_contractAddress] == false,"this contractAddress already exists");
        ERC20 erc20 = ERC20(_contractAddress);
        erc20.approve(uniswapV2Router02,115792089237316195423570985008687907853269984665640564039457584007913129639935);
        contractAddress[_contractAddress] = true;
    }
    /*
        删除支持的代币
    */
    function removeErc(address _contractAddress) public onlyOwner{
        require(contractAddress[_contractAddress],"this contractAddress already remove");
        ERC20 erc20 = ERC20(_contractAddress);
        erc20.approve(uniswapV2Router02,0);
        contractAddress[_contractAddress] = false;
    }
    /*
        交易
    */
    function transaction(bytes memory _data,uint256 _deadline,address _user) public onlyFactory{
        (uint256 _tokenA,uint256 _tokenB,address _pathA,address _pathB,uint256 _agencyFee) = getInfoBySlice(_data);
        require(contractAddress[_pathA] && contractAddress[_pathB],"please add the address supporting the contract");
        LasagnaFactory fac = LasagnaFactory(lasagnaFactory);
        // 转ERC20代理费到手续费池中
        fac.transferFromErc(_user,agencyFeePool,_agencyFee,_pathA);
        // 转swap交易的ERC20到当前地址
        fac.transferFromErc(_user,address(this),_tokenA,_pathA);
        /*
            type:0  --> 固定数量是A且是ERC20-ERC20，
            type:1  --> 固定数量是A且是ERC20-ETH,
            type:2  --> 固定数量是B且是ERC20-ERC20,
            type:3  --> 固定数量是B且是ERC20-ETH
        */
        uint256 _type = _deadline % 4;
        bool success;
        if(_type == 0){
            success = swapExactTokensForTokens(_tokenA,_tokenB,getPathByLen(3,_pathA,_pathB),_user,_deadline);
        }else if(_type == 1){
            success = swapExactTokensForEth(_tokenA,_tokenB,getPathByLen(2,_pathA,_pathB),_user,_deadline);
        }else if(_type == 2){
            success = swapTokensForExactTokens(_tokenA,_tokenB,getPathByLen(3,_pathA,_pathB),_user,_deadline);
            if(success){
                ERC20 erc = ERC20(_pathA);
                erc.transfer(agencyFeePool,erc.balanceOf(address(this)));   
            }
        }else if(_type == 3){
            if(_pathA == WETH){
                (success,) = WETH.call(abi.encodeWithSelector(SELECTOR_WITHDRAW,_tokenA));
                if(success){
                    payable(_user).transfer(_tokenA);
                }
            }else{
                success = swapTokensForExactEth(_tokenA,_tokenB,getPathByLen(2,_pathA,_pathB),_user,_deadline);
                ERC20 erc = ERC20(_pathA);
                uint256 balance = erc.balanceOf(address(this));
                if(success && balance > 0){
                    erc.transfer(agencyFeePool,balance);   
                }
            }
        }else{
            revert("type is error");
        }
        if(!success){
            ERC20 erc = ERC20(_pathA);
            erc.transfer(_user,_tokenA);
        }
    }
    function getPathByLen(uint256 _len,address _pathA,address _pathB) private view returns(address[] memory){
        if(_len == 2){
            address[] memory path = new address[](2);
            path[0] = _pathA;
            path[1] = _pathB;
            return path;
        }else{
            address[] memory path = new address[](3);
            path[0] = _pathA;
            path[1] = WETH;
            path[2] = _pathB;
            return path;
        }
    }
    /*
        固定数量 tokenA 兑换 tokenB
    */
    function swapExactTokensForTokens(uint256 _tokenA,uint256 _tokenB,address[] memory _path,address _to,uint256 _deadline) private returns(bool success){
        (success,) = uniswapV2Router02.call(abi.encodeWithSelector(SELECTOR_SWAP_EXACTTOEKN_FOR_TOKENS,_tokenA,_tokenB,_path,_to,_deadline));
    }
    /*
        tokenA 兑换固定数量 tokenB
    */
    function swapTokensForExactTokens(uint256 _tokenA,uint256 _tokenB,address[] memory _path,address _to,uint256 _deadline) private returns(bool success){
        (success,) = uniswapV2Router02.call(abi.encodeWithSelector(SELECTOR_SWAP_TOKENS_FOR_EXACTTOKEN,_tokenB,_tokenA,_path,_to,_deadline));
    }
    /*
        固定数量 tokenA 兑换 ETH
    */
    function swapExactTokensForEth(uint256 _tokenA,uint256 _tokenB,address[] memory _path,address _to,uint256 _deadline) private returns(bool success){
        (success,) = uniswapV2Router02.call(abi.encodeWithSelector(SELECTOR_SWAP_EXACTTOEKN_FOR_ETH,_tokenA,_tokenB,_path,_to,_deadline));
    }
    /*
        tokenA 兑换固定数量 ETH
    */
    function swapTokensForExactEth(uint256 _tokenA,uint256 _tokenB,address[] memory _path,address _to,uint256 _deadline) private returns(bool success){
        (success,) = uniswapV2Router02.call(abi.encodeWithSelector(SELECTOR_SWAP_TOKENS_FOR_EXACTETH,_tokenB,_tokenA,_path,_to,_deadline));
    }
    /*
        切割data，获取数据
    */
    function getInfoBySlice(bytes memory _msg) public pure returns(uint256 _tokenA,uint256 _tokenB,address _pathA,address _pathB,uint256 _agencyFee){
        assembly {
            _tokenA := mload(add(_msg,32))
            _tokenB := mload(add(_msg,64))
            _pathA := mload(add(_msg,96))
            _pathB := mload(add(_msg,128))
            _agencyFee := mload(add(_msg,160))
        }
    }
    /*
        取回所有的ETH
    */
    function withdrawEth() public onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
    }
    /*
        取回所有的ERC20
    */
    function withdrawErc(address _contractAddress) public onlyOwner{
        ERC20 erc = ERC20(_contractAddress);
        erc.transfer(msg.sender,erc.balanceOf(address(this)));
    }
    /*
        更新接收代理费的地址
    */
    function updateAgencyFeePool(address _agencyFeePool) public onlyOwner{
        agencyFeePool = _agencyFeePool;
    }
    /*
        更新工厂合约地址
    */
    function updateFactory(address _contractAddress) public onlyOwner{
        lasagnaFactory = _contractAddress;
    }
    /*
        仅限工厂合约调用
    */
    modifier onlyFactory(){
        require(lasagnaFactory == msg.sender, 'No authority');
        _;
    }
    /*
     修改管理员
    */
    function updateOwner(address _user) public onlyOwner{
        owner = _user;
    }
    /*
        仅限管理员操作
    */
    modifier onlyOwner(){
        require(owner == msg.sender, 'No authority');
        _;
    }
}

interface ERC20 {
    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external;
    function transferFrom(address sender, address recipient, uint256 amount) external;
    function approve(address to,uint256 value) external;
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}
interface LasagnaFactory{
    function transferFromErc(address _from,address _to,uint256 _value,address _contractAddress) external returns(bool); 
}