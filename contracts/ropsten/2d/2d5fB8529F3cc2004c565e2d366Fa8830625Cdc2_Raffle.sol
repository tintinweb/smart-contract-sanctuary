/**
 *Submitted for verification at Etherscan.io on 2021-02-04
*/

// contracts/Raffle.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

contract Owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface ERC20{
    function burnFrom(address _from, uint256 _value) external returns (bool success);
}

interface ERC721{
    enum MintType { AirdropNFT, RaffleNFT, PromoNFT }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata _data) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function mint(address to, uint16 tokenType, bytes calldata extraData) external returns (uint256);
    function mintTicket(address from, MintType NFTType, address referrer, uint256 quota) external returns(uint256 _newTokenId);
    function isRaffleOver() external view returns(bool);
}

contract Raffle is Owned{
    address private _tokenContractAddr;     //TSR代币地址
    address private _ticketContractAddr;    //门票合约地址
    address public bonusAddr;               //奖励合约地址
    uint256 public rafflePrice;             //单次抽奖消耗TSR数量 * 100000
    
    mapping(address => uint256) private _raffleCountOfUser;         //单用户抽奖次数
    mapping(address => uint256) private _yCardOfUser;               //用户抽到年卡数量
    
    
    // 用户参与抽奖次数
    function raffleCountOfUser(address user) public view returns(uint256){
        return _raffleCountOfUser[user];
    }
    
    // 抽奖并激活
    function raffleActivation(address to, address referrer, uint8 count) public returns (uint256 _newTokenId){
        ERC20 candidateContract = ERC20(_tokenContractAddr);
        require(candidateContract.burnFrom(to, rafflePrice * count));
        ERC721 ticketContract = ERC721(_ticketContractAddr);
        require(ticketContract.isRaffleOver());
        
        uint256 _amount;
        for(uint8 i=0;i<count;++i) {
            _amount = raffleRand(uint256(keccak256(abi.encodePacked(block.difficulty, now, to, i, _raffleCountOfUser[to]))) % 100) * (0.0001 ether);
            _newTokenId = ticketContract.mintTicket(to, ERC721.MintType.RaffleNFT, referrer, _amount);
            
            _raffleCountOfUser[to] += 1;
            if(_amount < 0.3 ether ){
                if(_yCardOfUser[to] == 0 && _raffleCountOfUser[to] % 10 == 0){
                    _extraBonus(to, 2, abi.encodePacked("超算粉丝"));
                }
            } else {
                uint8 randCardType = uint8(uint256(keccak256(abi.encodePacked(block.difficulty, now, to, _amount, _newTokenId))) % 5) + 3;
                _extraBonus(to, randCardType, abi.encodePacked("新年纪念卡"));
                _yCardOfUser[to] += 1;

            }
        }
        
    }
    
    // 抽奖随机数
    function raffleRand(uint num)public pure returns(uint256 rand) {
       uint16[100] memory yArr = [500,536,652,746,825,893,953,1005,1052,1094,1131,1165,1196,1223,1248,1270,1291,1308,1325,1339,1351,1362,1372,1380,1386,1392,1396,1400,1402,1403,1404,1403,1402,1400,1397,1394,1390,1386,1381,1376,1371,1365,1359,1353,1346,1340,1334,1328,1322,1317,1312,1307,1303,1300,1297,1296,1295,1295,1297,1300,1304,1311,1319,1329,1341,1355,1372,1391,1413,1439,1467,1499,1535,1574,1618,1666,1719,1776,1839,1908,1982,2063,2149,2243,2344,2453,2569,2694,2827,2970,3122,3284,3456,3640,3835,4042,4261,4494,4740,5000];
       rand = yArr[num];
    }
    
    //  调用空投合约，获取年卡、超算粉丝NFT方法
    function _extraBonus(address to, uint8 tokenType, bytes memory extraData) private returns (uint256) {
        return ERC721(bonusAddr).mint(to, tokenType, extraData);
    }
    
    // 配置门票、勋章、TSR合约地址
    function setAddr(address _ticketContract, address _bonusAddr, address _TSRContract) public onlyOwner {
        _ticketContractAddr = _ticketContract;
        bonusAddr = _bonusAddr;
        _tokenContractAddr = _TSRContract;
    }

    // 配置抽奖单价
    function setRafflePrice(uint _rafflePrice) public onlyOwner {
        rafflePrice =  _rafflePrice;
    }
}