pragma solidity ^0.4.18;

// import "./TokenERC20.sol";
import "./Ownable.sol";

contract ERC20Basic {
  function totalSupply() public constant returns (uint);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract TybFoundation is Ownable{
    ERC20Basic public tybToken;

    // 基金会目标地址
    address public foundation;
    // 技术团队目标地址
    address public technology;
    // 创始团队目标地址
    address public originator;
    
    // 钱包地址，挖矿分配
    address public wallet;
    // 黑洞地址
    address public blackHole;
    // TYB余额地址
    address public all;

    // mapping (address => uint256) public balanceOf;
    
    // 矿池余额
    uint256 public poolAmount;
    // 基金会余额
    uint256 public foundationAmount;
    // 技术团队余额
    uint256 public technologyAmount;
    // 创始团队余额
    uint256 public originatorAmount;
    
    // 云服务器租金池
    uint256 public rentalAmount;
    
    // 矿池发行量
    uint256 public issueAmount;
    // 矿池销毁量
    uint256 public destroyAmount;
    
    // 超级节点奖励余额
    uint256 public superRewordAmount;
    // 生态节点奖励余额
    uint256 public ZoologyRewordAmount;
    
    uint8 public decimals = 18;

    event Destroy(uint256 amount);
    event Mining(uint256 miningOut);
    event Rental(uint256 amount);
    event SurrenderRental(uint256 amount);
    event SuperReword(uint256 reword);
    event ZoologyReword(uint256 reword);
    

    constructor(address _tybToken, address _all, address _foundation, address _technology, address _originator,  address _wallet, address _blackHole, uint256 _rental) public{
        // tybToken = TokenERC20(_tybToken);
        tybToken = ERC20Basic(_tybToken);

        all = _all;
        foundation = _foundation;
        technology = _technology;
        originator = _originator;
        wallet = _wallet;
        blackHole = _blackHole;
        
        poolAmount = 600000000 * 10 ** uint256(decimals);
        foundationAmount = 50000000 * 10 ** uint256(decimals);
        technologyAmount = 50000000 * 10 ** uint256(decimals);
        originatorAmount = 50000000 * 10 ** uint256(decimals);
        
        superRewordAmount = 66 * 600000 * 10 ** uint256(decimals);
        ZoologyRewordAmount = 330 * 160000 * 10 ** uint256(decimals);

        rentalAmount = _rental * 10 ** uint256(decimals);
    }

    function setBlackHole(address _blackHole) public onlyOwner{
        blackHole = _blackHole;
    }

    function setFoundation(address _foundation) public onlyOwner{
        foundation = _foundation;
    }

    function setTechnology(address _technology) public onlyOwner{
        technology = _technology;
    }

    function setOriginator(address _originator) public onlyOwner{
        originator = _originator;
    }

    function setWallet(address _wallet) public onlyOwner{
        wallet = _wallet;
    }

    function setAll(address _all) public onlyOwner{
        all = _all;
    }

    // 租用矿机
    function addRental(uint256 _rental) public onlyOwner {
        rentalAmount = rentalAmount + _rental;

        emit Rental(_rental);
    }

    // 退租， 退租的数量和需要销毁的数量
    function surrenderRental(uint256 _amount, uint256 _destroy) public onlyOwner {
        require(_amount >= _destroy);

        rentalAmount = rentalAmount - _amount;
        destroyAmount = destroyAmount + _destroy;

        tybToken.transferFrom(all, wallet, _amount - _destroy);
        tybToken.transferFrom(all, blackHole, _destroy);

        emit SurrenderRental(_amount);
        emit Destroy(_destroy);
    }

    // 挖矿，挖出的数量和销毁的数量
    function mining(uint256 _miningOut, uint256 _destroy) public onlyOwner {
        require(poolAmount >= _miningOut);
        require(_miningOut >= _destroy);

        issueAmount = issueAmount + _miningOut;
        poolAmount = poolAmount - _miningOut;
        destroyAmount = destroyAmount + _destroy;

        tybToken.transferFrom(all, wallet, _miningOut - _destroy);
        tybToken.transferFrom(all, blackHole, _destroy);

        emit Mining(_miningOut);
        emit Destroy(_destroy);
    }

    function superReword(uint256 _reword) public onlyOwner {
        require(superRewordAmount >= _reword);

        superRewordAmount = superRewordAmount - _reword;

        tybToken.transferFrom(all, wallet, _reword);

        emit SuperReword(_reword);
    }

    function zoologyReword(uint256 _reword) public onlyOwner {
        require(ZoologyRewordAmount >= _reword);

        ZoologyRewordAmount = ZoologyRewordAmount - _reword;

        tybToken.transferFrom(all, wallet, _reword);

        emit ZoologyReword(_reword);
    }
}