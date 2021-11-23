//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;


import "./SafeMath.sol";
import "./Ownable.sol";


interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 amount) external returns (bool);
}

//   function getPair(address tokenA, address tokenB) external view returns (address pair);
interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
}

contract PICNICPresale is Ownable {

    using SafeMath for uint256;
    
    uint count = 0;
    
    address public criteriaTokenAddr = 0xd9145CCE52D386f254917e481eB44e9943F39138;
    address devTeamAddr = 0xE813d775f33a97BDA25D71240525C724423D4Cd0;
    
    //# Ethereum mainnet, and the Ropsten, Rinkeby, Görli, and Kovan testnets
    address UniswapV2FactoryAddr = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address UniswapV2Router02Addr = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    
    
    //# PancakeSwap on BSC testnet:
    address pancakeSwapFactoryAddr = 0x6725F303b657a9451d8BA641348b6761A6CC7a17;
    address pancakeSwapRouterAddr = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;

    //# BNB address
    address BNBAddr = 0xB8c77482e45F1F44dE1745F52C74426C631bDD52;
    
    enum PoolType{ UNI, PCS }

    
    mapping(uint256 => PresaleContract) public presaleContract;
    mapping(uint256 => PresaleContractStatic) public presaleContractStatic;

    
    struct PresaleContractStatic {
        address preSaleContractAddr;
        string symbol;
        string name;
        PoolType _poolType;
        address pairAddress;
    }
    
    struct PresaleContract {
        // id
        uint256 presaleId;
        
        // Contract Info
        address preSaleContractAddr;
        
        // Token distribution
        uint256 reservedTokensPCForLP;      // 70% = 0.7   =>   1700/1.7 = 700
        uint256 tokensForSale;              // 1000
        uint256 remainingTokensForSale;
        uint256 accumulatedBalance;

        // Participation Criteria
        uint256 priceOfEachToken;
        uint256 minTokensForParticipation;
        uint256 minContibution;        
        uint256 maxContibution;
        uint256 startedAt;
        uint256 expiredAt;
        
    }
    
    function setPresaleContractInfo(
        // Contract Info
        address _preSaleContractAddress,

        uint8 _reservedTokensPCForLP,
        uint256 _tokensForSale,

        // Participation Criteria
        uint256 _priceOfEachToken,
        uint256 _minTokensForParticipation,
        uint256 _minContibution,
        uint256 _maxContibution,
        uint256 _startedAt,
        uint256 _expiredAt,
        PoolType _poolType
        
        ) public onlyOwner returns(uint){


        count++;
        
        address _pairAddr = _poolType == PoolType.UNI ?
            IFactory(UniswapV2FactoryAddr).createPair(_preSaleContractAddress, BNBAddr):
            IFactory(pancakeSwapRouterAddr).createPair(_preSaleContractAddress, BNBAddr);
        
        presaleContractStatic[count] = PresaleContractStatic(
            _preSaleContractAddress,
            IERC20(_preSaleContractAddress).symbol(),
            IERC20(_preSaleContractAddress).name(),
            _poolType,
            _pairAddr
        );

        presaleContract[count] = PresaleContract(
            count,
            _preSaleContractAddress,
            
            // Token distribution
            _reservedTokensPCForLP,             // 70% = 0.7   =>   1700/1.7 = 700
            _tokensForSale,                     // 1000    tokensForSale
            _tokensForSale,                     // remainingTokensForSale = tokensForSale (initially)
            0,                                  // accumulatedBalance

            // Participation Criteria
            _priceOfEachToken,
            _minTokensForParticipation,
            _minContibution,
            _maxContibution,
            _startedAt,
            _expiredAt
        );
        
        return count;
    }

    
    function getLatestPresaleContractStaticInfo() public view returns(PresaleContractStatic memory){
        return presaleContractStatic[count];
    }
    
    function getLatestPresaleContractInfo() public view returns(PresaleContract memory){
        return presaleContract[count];
    }
    
    function updatePresaleContractInfo (
        uint256 _id, // id
        
        
        uint8 _reservedTokensPCForLP,
        uint256 _tokensForSale,
            
        // Participation Criteria
        uint256 _priceOfEachToken,
        uint256 _minTokensForParticipation,
        uint256 _minContibution,      
        uint256 _maxContibution,
        uint256 _startedAt,
        uint256 _expiredAt

        ) public onlyOwner returns(PresaleContract memory){

        PresaleContract memory currentProject = presaleContract[_id];

        presaleContract[_id]  = PresaleContract(
            _id,
            currentProject.preSaleContractAddr,
            
            // Token distribution
            _reservedTokensPCForLP,                     // 70% = 0.7   =>   1700/1.7 = 700
            _tokensForSale,                             // 1000    tokensForSale
            _tokensForSale,                             // remainingTokensForSale = tokensForSale (initially)
            currentProject.accumulatedBalance,          // accumulatedBalance
            
            // Participation Criteria
            _priceOfEachToken,
            _minTokensForParticipation,
            _minContibution,
            _maxContibution,
            _startedAt,
            _expiredAt
        );
            
        
        return presaleContract[_id];
    }

    function deletePresaleContractInfo (uint256 _id) public onlyOwner returns(bool){
        delete presaleContract[_id];
        delete presaleContractStatic[_id];

        return true;
    }


    function buyTokensOnPresale(uint256 _id, uint256 _numOfTokensRequested) payable public returns (bool){
        
        require(block.timestamp > presaleContract[_id].startedAt, "Presale hasn't begin yet. please wait");
        require(block.timestamp < presaleContract[_id].expiredAt, "Presale is over. Try next time");

        require(presaleContract[_id].remainingTokensForSale <= IERC20(presaleContract[_id].preSaleContractAddr).balanceOf(address(this)), "insufficient tokens to fulfill this order");
        
        require(_numOfTokensRequested <= presaleContract[_id].remainingTokensForSale, "insufficient tokens to fulfill this order");
        require(msg.value >= _numOfTokensRequested*presaleContract[_id].priceOfEachToken, "insufficient funds");

        uint256 PICNICTokensOfUser = IERC20(criteriaTokenAddr).balanceOf(msg.sender);
        require(PICNICTokensOfUser >= presaleContract[_id].minTokensForParticipation, "Not enough tokens to participate. Should be atleast 250");
        
    
        require(_numOfTokensRequested >= presaleContract[_id].minContibution, "Contribution is low, Please request more than minimum contribution");
        require(_numOfTokensRequested + IERC20(presaleContract[_id].preSaleContractAddr).balanceOf(address(msg.sender)) <= presaleContract[_id].maxContibution, "Contribution is high, Please request less than maximum contribution");

        
        bool tokenDistribution = IERC20(presaleContract[_id].preSaleContractAddr).transfer(address(msg.sender), _numOfTokensRequested);
        
        if(tokenDistribution == true){
            presaleContract[_id].accumulatedBalance += msg.value;
            presaleContract[_id].remainingTokensForSale -= _numOfTokensRequested;
            return true;
        } else {
            return false;
        }
        

    }
    
        
        function endPresale(uint _id) public onlyOwner returns (uint, uint, uint){
            
            PresaleContract memory currentProject = presaleContract[_id];
            
            require(block.timestamp > currentProject.expiredAt, "Presale is not over yet");

            
            uint256 revenueFromPresale = currentProject.accumulatedBalance;
            require(revenueFromPresale > 0, "No revenue to add liquidity");

        
            uint256 totalTokensSold = currentProject.tokensForSale - currentProject.remainingTokensForSale;
            
            uint256 tokensToAddLiquidity = totalTokensSold.mul(currentProject.reservedTokensPCForLP).div(100);
            uint256 poolShareBNB = revenueFromPresale.mul(currentProject.reservedTokensPCForLP).div(100);
            uint256 devTeamShareBNB = revenueFromPresale.sub(poolShareBNB);
            
            (bool devTeam) = payable(devTeamAddr).send(devTeamShareBNB);
            require(devTeam);
            
            PoolType _poolType =  presaleContractStatic[_id]._poolType;
            
            (uint amountA, uint amountB, uint liquidity) = _poolType == PoolType.UNI ?
                IRouter(UniswapV2Router02Addr).addLiquidity(
                    currentProject.preSaleContractAddr,
                    BNBAddr,
                    poolShareBNB,
                    tokensToAddLiquidity,
                    poolShareBNB,
                    tokensToAddLiquidity,
                    devTeamAddr,
                    block.timestamp + 5*60
                ):
                IRouter(pancakeSwapFactoryAddr).addLiquidity(
                    currentProject.preSaleContractAddr,
                    BNBAddr,
                    poolShareBNB,
                    tokensToAddLiquidity,
                    poolShareBNB,
                    tokensToAddLiquidity,
                    devTeamAddr,
                    block.timestamp + 5*60
                );
            
            currentProject.accumulatedBalance = 0;
            
            return (amountA, amountB, liquidity);
            
        }
        
        function factory(PoolType _poolType) public view returns (address){
            address  _factoryAddr;
            
            _factoryAddr = _poolType == PoolType.UNI ?
             IRouter(UniswapV2Router02Addr).factory():
             IRouter(pancakeSwapFactoryAddr).factory();
             
             return _factoryAddr;
          }

        // Helping functions;
        function preSaleTokenBalance (uint256 _id, address _address) public view returns(uint256){
            return IERC20(presaleContract[_id].preSaleContractAddr).balanceOf(_address);
        }
        
        function PICNICBalanceOfUser(address _address) public view returns (uint){
            return IERC20(criteriaTokenAddr).balanceOf(address(_address));
        }
    

}