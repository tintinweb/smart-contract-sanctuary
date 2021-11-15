// SPDX-License-Identifier: GPLv2
//TODO: upgrade to solidity 8
pragma solidity ^0.5.17;
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/upgrades/contracts/upgradeability/ProxyFactory.sol";

interface IPersonal {
    function initialize(
        address payable _investor, 
        address _strategist, 
        uint256 _riskLevel,
        address _networkNativeToken,
        address _yieldToken
    ) external;
}

interface IERC20Permit {
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
}

interface YZap {
    function routerAddress() external view returns (address);
}

interface ITokenExchangeRouter {
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

contract Factory is ProxyFactory, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Exchange{
        string name;//name is to identify exchange type. Useful for scripts
        address inContractAddress;
        address outContractAddress;
    }

    struct AddressInfo{
        string description;//brief info about address. May be helpfull for clients
        uint256 riskLevel;//percentage, 33 = 33%, no decimals
        bool approvedForStaticFunctions;
        bool approvedForDirectCallFunction;
    }

    Exchange[] exchanges;
    mapping (address => AddressInfo) public addresses;
    mapping (address => address[]) public personalContracts;//user address => personal contracts address
    mapping (address => address) public personalContractsToUsers;//personal contract => user address
    mapping (address => uint256) public tokenToExchangeIndex;//token address => exchange index (in exchanges array)

    uint256 constant version = 3;
    uint256 public onRewardNativeDevelopmentFund = 500;//5.00%
    uint256 public onRewardNativeBurn = 500;//5.00%
    uint256 public onRewardYieldDevelopmentFund = 250;//2.50%
    uint256 public onRewardYieldBurn = 250;//2.50%
    address public developmentFund;//this address collects developmentFund
    address public personalLibImplementation;
    address public networkNativeToken;//WETH or WBNB
    address public yieldToken;
    address public yieldTokenPair;//BUSD for example. (not lp) This is in case it is not networkNative and we have to do extra swap; 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56

    //stake rewards options (will be used in PersonalLibrary, stakeReward function)
    uint256 public yieldStakeExchange;
    address public yieldStakeContract;
    uint256 public yieldStakeStrategy;
    address public yieldStakePair;
    uint256 public yieldStakePid;
    uint256 public yieldStakeLockSeconds;
    address public yieldStakeRewardToken;

    bool public skipApprove = true;//set true if there is no appropriate pool approval functionality implemented
        
    event PersonalContractCreated(address _investorAddress, address personalContractAddress, address tokenToInvest, uint256 riskLevel, uint256 strategistEth);
    event PersonalContractEvent(address _investorAddress, address personalContractAddress, string eventType, bytes data);
    event newExchangeAdded(string name, address _in, address _out);

    constructor (
        address _developmentFund,
        address _personalLibImplementation,
        address _networkNativeToken,
        address _yieldToken,
        address _yieldTokenPair
    ) public {
        require(_developmentFund != address(0), '_developmentFund is empty');
        require(_personalLibImplementation != address(0), '_personalLibImplementation is empty');
        require(_networkNativeToken != address(0), '_networkNativeToken is empty');
        require(_yieldToken != address(0), '_yieldToken is empty');

        developmentFund = _developmentFund;
        networkNativeToken = _networkNativeToken;
        yieldToken = _yieldToken;
        yieldTokenPair = _yieldTokenPair;
        personalLibImplementation = _personalLibImplementation;

        //example of pre-approved addresses
        //addresses[0xeaB819E2BE63FFC0dF64E7BBA4DDB3bDEa280310] = AddressInfo('Pancake:BUSD-BNB', 25, true, true);
        //addresses[0x221ED06024Ee4296fB544a44cfEDDf7c9f882cF3] = AddressInfo('Pancake:ETH-BNB', 55, true, true);


        exchanges.push(Exchange('', address(0), address(0)));//hardcoded reminder to skip index 0
        //saving gas...
        exchanges.push(Exchange('PancakeswapV1', 0xe40d348D677530b5692150Fe6C98bb06749723E4, 0x2C501Ac9271b2Dc3D14A152979aE7B32ED0BeE7C));
        exchanges.push(Exchange('PancakeswapV2', 0x854962B2D89198e9f71A83DAb3413a5270DcD172, 0x690d0150d41cF2d93Ec1a8F7A2229D8BAA3D963a));
        exchanges.push(Exchange('SushiswapBSC', 0xFA8b1E26B7505e1fC06EB31476a752F2454BA616, 0x497e1CdF2Bd3C60196dfCf106c2b4B12427f45F7));
        exchanges.push(Exchange('Cafeswap', 0xE9C23Ab1C09ACd5902675D11fD30E6Eb52514dD9, 0xF6049Aae2cC4E425a14dec4F061931C4388982f3));
        exchanges.push(Exchange('Bakeryswap', 0x904277f952f4D033A9A1de2fA5DE79a165FbeC2E, 0x6759479900B952962a25b95ec059a7Ac6248F754));
        exchanges.push(Exchange('Jetswap', 0x64F5Ef28102d52fb45857D2f7397D23B9E58439C, 0x5262BCFD90Dd098bcBEE3C08B305bf11B79cEE6A));
        exchanges.push(Exchange('Thunderswap', 0x2559e1e8128F62fB207bCCA9a0f07a58921719f3, 0x5BaA9F34bDa51B212b06b9D07af22b9762eE1AE4));
        exchanges.push(Exchange('Kebab', 0x9e364a8aC4C25Ff03BB505070DcCE693Ea2Bc95B, 0x95B751B2D6142Bca1037009ecdA20799465d9813));
        exchanges.push(Exchange('Mdex', 0x18883853028b8c6430d3B0436EffF472817A4345, 0x2cED2c96D9E47aD55d5d082Fb0F40B8a50D4159F));
        exchanges.push(Exchange('WaultSwap', 0x57b3fc2a109434f457f7aeB367c29Cd6c5d8AD63, 0x6a94cDAf47cC289f5bD878ee70b835F908d2de29));
        exchanges.push(Exchange('BSCswap', 0x5167449Ea455a8DeAA3EeC0650f71e5Ea3d06853, 0xb84705EBb8503ee7C287c3BB90B1A54BaC6Cc0b9));
        exchanges.push(Exchange('Palmswap', 0x77af866513C192d582fce14114A8B33e713B5260, 0x030568D6a6723f0AbC3aa537190388a34911F1c4));
        exchanges.push(Exchange('Valuedefi', 0x1d42beF1C8AFc39c922593E126c8E39ec9ED7133, 0xFE8f34889832fECc1eABdbD489843B446B631d54));
        exchanges.push(Exchange('Slimeswap', 0xAa21982F91140139Dc35810097af926d8385674F, 0xFFD22F199d6e8e18d86fD363dfE6491ca91DAe13));
        exchanges.push(Exchange('UniswapBSC', 0x05Cb1527d49305E2226C235893eD5991b7d91dD5, 0x10bda135D568690b22B288007906403FcC663422));
        exchanges.push(Exchange('PokemoonSwap', 0x2496112Ed1E84ee1Ea59d41AB7F0E262F64D9EDC, 0x328ccdddf9BBcA1314DDeE3289308A9cf7b1242f));
        exchanges.push(Exchange('SwipeSwap', 0x47C884a94fd0Cd919e45b1d914fA2E6fEA4276Ec, 0x0f575f8aAf10fcd66808535596e2e0C0585033f4));
    }

    /**
    @notice This function is used to return total amount of exchanges added
    @return count of exchanges
    */
    function exchangesCount() external view returns (uint256){
        return exchanges.length - 1;//because we skipped 0 index
    }

    /**
    @notice This function is used to return addresses of Liquidity Helper contracts
    @notice This contracts help us to buy/sell LP tokens in one transaction
    @param _exchangeIndex is liquidity pool index, starts from 1
    @return exchange name, in and out address
    */
    function getExchange(uint256 _exchangeIndex) external view returns (string memory, address, address) {
        return (
            exchanges[_exchangeIndex].name, 
            exchanges[_exchangeIndex].inContractAddress, 
            exchanges[_exchangeIndex].outContractAddress
        );
    }

    /**
    @notice This function is used to return addresses of Liquidity Helper contracts by name
    @notice We don't care about gas here, this function mostly will be called by back end
    @param _name name of exchange
    @return in and out address
    */
    function getExchangeByName(string calldata _name) external view returns (uint256, address, address) {

        bytes32 needle = keccak256(abi.encodePacked(_name));
        for(uint256 c = 0; c < exchanges.length; c++){
            if(needle == keccak256(abi.encodePacked(exchanges[c].name))){
                return (
                    c,
                    exchanges[c].inContractAddress, 
                    exchanges[c].outContractAddress
                );
            }
        }

        return (0, address(0),  address(0));
    }
    
    /**
    @notice This function is used to return total amount of personal contract created by one user
    @return count of personal contracts
    */
    function personalContractsCount(address _user) external view returns (uint256){
        return personalContracts[_user].length;
    }

    /**
    @notice This function is used to return "in" liquidity helper contract address.
    @param _exchangeIndex is liquidity pool index, starts from 1
    @return address of the contract. reverts if not set (to prevent any losses)
    */
    function getInContract(uint256 _exchangeIndex) external view returns (address) {
        address _inContractAddress = exchanges[_exchangeIndex].inContractAddress;//saves gas
        require(_inContractAddress != address(0), "inContractAddress is not set");
        return _inContractAddress;
    }

    /**
    @notice This function is used to return "out" liquidity helper contract address.
    @param _exchangeIndex is liquidity pool index, starts from 1
    @return address of the contract. reverts if not set (to prevent any losses)
    */
    function getOutContract(uint256 _exchangeIndex) external view returns (address) {
        address _outContractAddress = exchanges[_exchangeIndex].outContractAddress;//saves gas
        require(_outContractAddress != address(0), "outContractAddress is not set");
        return _outContractAddress;
    }
    

    /**
    @notice This function allows to create personal contract for a user by owner
    @notice for more details see _createPersonalContract() function
    */
    function createPersonalContractForUser(
        address payable _investorAddress, 
        address payable _strategistAddress, 
        uint256 _strategistEth,
        address _tokenToInvest,
        uint256 _riskLevel,
        uint256 _amountToPersonalContract,
        uint256 _amountToStrategist
    ) onlyOwner nonReentrant payable external returns (address) {
        return _createPersonalContract(
            _investorAddress, 
            _strategistAddress, 
            _strategistEth, 
            _tokenToInvest, 
            _amountToPersonalContract, 
            _amountToStrategist,
            _riskLevel,
            0,
            0,
            0
        );
    }

    /**
    @notice creates personal contract along with erc20 token transfer in one transaction
    @notice for more details see _createPersonalContract() function
    */
    function createPersonalContractWithPermit(
        address payable _strategistAddress, 
        uint256 _strategistEth,         
        address _tokenToInvest,
        uint256 _amountToPersonalContract,
        uint256 _amountToStrategist, 
        uint256 _riskLevel,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) nonReentrant payable external returns (address) {
        return _createPersonalContract(
            msg.sender, 
            _strategistAddress, 
            _strategistEth, 
            _tokenToInvest,
            _amountToPersonalContract,
            _amountToStrategist,
            _riskLevel,
            v, 
            r, 
            s
        );
    }

    /**
    @notice most simple way to create personal contract
    @notice for more details see _createPersonalContract() function
    */
    function createPersonalContract(
        address payable _strategistAddress,
        uint256 _strategistEth,
        address _tokenToInvest,
        uint256 _amountToPersonalContract,
        uint256 _amountToStrategist,
        uint256 _riskLevel
    ) nonReentrant payable external returns (address) {
        return _createPersonalContract(
            msg.sender, 
            _strategistAddress, 
            _strategistEth, 
            _tokenToInvest,
            _amountToPersonalContract,
            _amountToStrategist,
            _riskLevel,
            0, 
            0, 
            0
        );
    }

    /**
    @notice This function allows to create personal contract for a user by owner
    @notice Along with contract creation owner can send eth / erc20 token that will be transferred to personal contract
    @notice Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in https://eips.ethereum.org/EIPS/eip-2612
    @param _investorAddress this address will be able to claim all funds and rewards
    @param _strategistAddress personal contract will allow invest commands only from this address
    @param _strategistEth how much of eth should be sent to strategist address (if any). This eth is used to pay for gas fees
    @param _tokenToInvest address of an ERC20 token to invest (0x0 if ether)
    @param _amountToPersonalContract how much of ERC20 (if any) will be transfer to the personal contract
    @param _amountToStrategist how much of ERC20 (if any) will be converted to eth and sent to the strategist address
    @param _riskLevel personal contract will work with pools only if their risk level is less than this variable. 0-100%
    @param v signature param, see eip-2612
    @param r signature param, see eip-2612
    @param s signature param, see eip-2612
    @return address of the contract. reverts if failed to create
    */
    function _createPersonalContract(
        address payable _investorAddress, 
        address payable _strategistAddress, 
        uint256 _strategistEth, 
        address _tokenToInvest,
        uint256 _amountToPersonalContract,
        uint256 _amountToStrategist,
        uint256 _riskLevel,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) internal returns (address) {
        require(_investorAddress != address(0), 'EMPTY_INVESTOR_ADDRESS');
        //require(personalContracts[_investorAddress] == address(0), 'CONTRACT_EXISTS');

        address payable personalContractAddress = address(uint160(clonePersonalLibrary()));
        require(personalContractAddress != address(0), 'personalContractAddress is 0x00..');

        IPersonal(personalContractAddress).initialize(_investorAddress, _strategistAddress, _riskLevel, networkNativeToken, yieldToken);
        personalContracts[_investorAddress].push(personalContractAddress);
        personalContractsToUsers[personalContractAddress] = _investorAddress;

        if(msg.value > 0){
            if(_strategistEth > 0){
                require(_strategistEth < msg.value, '_strategistEth >= msg.value');
                _strategistAddress.transfer(_strategistEth);   
            }
            //personalContractAddress.transfer(msg.value.sub(_strategistEth));
            sendValue(personalContractAddress, msg.value.sub(_strategistEth));
        }
        if(address(_tokenToInvest) != address(0)){

            if(v > 0){//permittable token 
                IERC20Permit(_tokenToInvest).permit(
                    msg.sender, 
                    address(this), 
                    _amountToPersonalContract.add(_amountToStrategist), 
                     uint256(-1), 
                     v, 
                     r, 
                     s
                );
            }

            if(_amountToPersonalContract > 0){
                IERC20(_tokenToInvest).safeTransferFrom(_investorAddress, personalContractAddress, _amountToPersonalContract);
            }

            if(_amountToStrategist > 0){
                IERC20(_tokenToInvest).safeTransferFrom(_investorAddress, address(this), _amountToStrategist);
                convertTokenToETH(_strategistAddress, _tokenToInvest, _amountToStrategist);
            }

        }

        emit PersonalContractCreated(_investorAddress, personalContractAddress, _tokenToInvest, _riskLevel, _strategistEth);
        return personalContractAddress;
    }

    /**
    @notice Convert tokens to eth or wbnb
    @param _toWhomToIssue personal contract will work with pools only if their risk level is less than this variable. 0-100%
    @param _tokenToExchange personal contract will work with pools only if their risk level is less than this variable. 0-100%
    @param _amount personal contract will work with pools only if their risk level is less than this variable. 0-100%
    */
    function convertTokenToETH(address _toWhomToIssue, address _tokenToExchange, uint256 _amount) internal {

        (, address router, address[] memory path) = checkIfTokensCanBeExchangedWith1Exchange(_tokenToExchange, networkNativeToken);
        IERC20(_tokenToExchange).approve(router, _amount);
        ITokenExchangeRouter(router).swapExactTokensForETH(
            _amount,
            1,
            path,
            _toWhomToIssue,
            block.timestamp
        );
    }
    
    /**
    @notice in case any changes on Uniswap, Sushiswap, Curve and so on..
    @notice Please refer to personalLibrary if interface functions are match
    @param _exchangeIndex is liquidity pool index, starts from 1
    @param _in new address of "YZapIn" contract
    @param _out new address of "YZapOut" contract
    */
    function changeContracts(uint256 _exchangeIndex, address _in, address _out) onlyOwner external {
        exchanges[_exchangeIndex].inContractAddress = _in;
        exchanges[_exchangeIndex].outContractAddress = _out;
    }

    /**
    @notice in case new platform required. Pickle for example
    @param name the new platform identification (optional)
    @param _in new address of "YZapIn" contract
    @param _out new address of "YZapOut" contract
    */
    function addExchange(string calldata name, address _in, address _out) onlyOwner external {
        require(_in != address(0), 'in address is empty');
        require(_out != address(0), 'out address is empty');

        exchanges.push(Exchange(name, _in, _out));
        emit newExchangeAdded(name, _in, _out);
    }

    
    /**
    @notice This function is used to SET address of a contract where convertTokenToETH(address,address,uint256) can be called.
    @notice by default this function is located in UniswapV2_YZapIn.sol or PancakeswapV2_YZapIn.sol
    @param _token the token that requires custom exchange. address(0) means default exchange
    */
    function setTokenToExchangeIndex(address _token, uint256 exchangeIndex) onlyOwner external {
        tokenToExchangeIndex[_token] = exchangeIndex;
    }

   /**
    @notice This function is used to GET address of contract, where convertTokenToETH(address,address,uint256) can be called.
    @notice also it generate path for exchanging the tokens;
    @notice In future we will add best exchange search, comparing by potential price impact, pool size, etc..
    @return address of the contract. reverts if not found and default not set
    @return path of the contract. reverts if not found and default not set
    */
    function checkIfTokensCanBeExchangedWith1Exchange(address _token1, address _token2) public view returns (bool, address, address[] memory) {

        uint256 routerIndex1 = tokenToExchangeIndex[address(0)];//default
        uint256 routerIndex2 = tokenToExchangeIndex[address(0)];//default

        if(_token1 != networkNativeToken && tokenToExchangeIndex[_token1] > 0){
            routerIndex1 = tokenToExchangeIndex[_token1];
        } 
        
        if(_token2 != networkNativeToken && tokenToExchangeIndex[_token2] > 0){
            routerIndex2 = tokenToExchangeIndex[_token2];
        } 

        require(routerIndex1 > 0 && routerIndex2 > 0, 'not router index defined');

        bool isThereNetworkNative = (_token1 == networkNativeToken || _token2 == networkNativeToken);
        bool isThereYieldToken = (_token1 == yieldToken || _token2 == yieldToken);
        bool extraStepForYield = (yieldTokenPair != address(0) && yieldTokenPair != networkNativeToken);

        bool same = (routerIndex1 == routerIndex2 || isThereNetworkNative);


        /*if(!same){
            // check maybe there is the first token is on the second tokens pool (or vice versa)
            //if so, set same = true and routers = to the new common.
        }*/

        if(same){

            if(isThereNetworkNative && isThereYieldToken && extraStepForYield){
                uint256 routerIndex = _token1 == yieldToken ? routerIndex1:routerIndex2;
                address[] memory path = new address[](3);
                path[0] = _token1;
                path[1] = yieldTokenPair;//in cause no WBNB for YIELD
                path[2] = _token2;
                return (true, YZap(exchanges[routerIndex].inContractAddress).routerAddress(), path);
            }

            if(!isThereYieldToken || !extraStepForYield){
                uint256 length = isThereNetworkNative?2:3;
                address[] memory path = new address[](length);

                path[0] = _token1;
                if(length == 3){
                    //note: in future there will be sophisticated mechanism to find best path
                    path[1] = networkNativeToken;
                    path[2] = _token2;
                } else {
                    path[1] = _token2;//WETH or WBNB
                }
                return (true, YZap(exchanges[routerIndex1].inContractAddress).routerAddress(), path);
            }

            address[] memory path = new address[](4);
            path[0] = _token1;
            uint256 routerIndex;
            if(_token1 == yieldToken){
                path[1] = yieldTokenPair;//BUSD, cause no WBNB for YIELD
                path[2] = networkNativeToken;
                routerIndex = routerIndex1;
            }else{
                path[1] = networkNativeToken;
                path[2] = yieldTokenPair;//BUSD, cause no WBNB for YIELD
                routerIndex = routerIndex2;
            }
            path[3] = _token2;
            return (true, YZap(exchanges[routerIndex].inContractAddress).routerAddress(), path);


        } else {

            uint256 length = (_token1 == yieldToken && extraStepForYield)?3:2;
            address[] memory path = new address[](length);

            path[0] = _token1;
            if(length == 3){
                path[1] = yieldTokenPair;//BUSD, cause no WBNB for YIELD;
                path[2] = networkNativeToken;
            } else {
                path[1] = networkNativeToken;//WETH or WBNB
            }
            return (false, YZap(exchanges[routerIndex1].inContractAddress).routerAddress(), path);

        }

    }

    /**
    @notice allows set different personal library for new users.  
    @notice UPDATE: commented this due to implementation differerences for new and old investors.
    @notice UPDATE: for now we will use factory update even if slight change required on personal lib
    @param _implementation address of personal lib
    */
    /*function setPersonalLibImplementation(address _implementation) onlyOwner external {
        require(_implementation != address(0));
        personalLibImplementation = _implementation;
    }*/


    /**
    @param _developmentFund new development fund address
    */
    function setDevelopmentFund(address _developmentFund) onlyOwner external {
        require(_developmentFund != address(0), 'empty address');
        developmentFund = _developmentFund;
    }

    function setOnRewardNativeFee(uint256 _onRewardNativeDevelopmentFund, uint256 _onRewardNativeBurn) onlyOwner external {
        onRewardNativeDevelopmentFund = _onRewardNativeDevelopmentFund;
        onRewardNativeBurn = _onRewardNativeBurn;
    }

    /**
    @notice set perentage of tokens that should be transferred to development fund on claim reward function call (in personal contract)
    @param _onRewardYieldDevelopmentFund to develpment fund, 500 = 5%
    @param _onRewardYieldBurn buy & burn yeild tokens, 500 = 5%
    */
    function setOnRewardYieldFee(uint256 _onRewardYieldDevelopmentFund, uint256 _onRewardYieldBurn) onlyOwner external {
        onRewardYieldDevelopmentFund = _onRewardYieldDevelopmentFund;
        onRewardYieldBurn = _onRewardYieldBurn;
    }

    /**
    @notice personal contract will need this for staking rewards tokens into yield pool. 
    @param _yieldStakeContract address of the pool
    @param _yieldStakePair address of the lp pair to stake
    @param _yieldStakeExchange exhange index where lp pair can be minted
    @param _yieldStakePid in master chef contract (if any)
    @param _yieldStakeStrategy index from Strategy enum (personal library)
    @param _yieldStakeLockSeconds period on which can not unstake the reward
    @param _yieldStakeRewardToken the reward (FARM or BANANA for example) we get for staking our rewards
    */
    function setYieldStakeSettings(
        address _yieldStakeContract, 
        address _yieldStakePair, 
        uint256 _yieldStakeExchange, 
        uint256 _yieldStakePid,
        uint256 _yieldStakeStrategy,
        uint256 _yieldStakeLockSeconds,
        address _yieldStakeRewardToken
    ) onlyOwner external {
        yieldStakeContract = _yieldStakeContract;
        yieldStakePair = _yieldStakePair;
        yieldStakeExchange = _yieldStakeExchange;
        yieldStakePid = _yieldStakePid;
        yieldStakeStrategy = _yieldStakeStrategy;
        yieldStakeLockSeconds = _yieldStakeLockSeconds;
        yieldStakeRewardToken = _yieldStakeRewardToken;
    }

    /**
    @notice get stake yield details with one call
    */
    function getYieldStakeSettings(
    ) view external returns(address, address, uint256, uint256, uint256, uint256, address) {
        return (yieldStakeContract, yieldStakePair, yieldStakeExchange, yieldStakePid, yieldStakeStrategy, yieldStakeLockSeconds, yieldStakeRewardToken);
    }

   /**
    @notice in case someone mistakenly sends tokens to the factory, we can send it back via this method
    @return true or false
    */
    function rescueTokens(address tokenAddress, address sendTo, uint256 amount) onlyOwner external returns (bool){
        return IERC20(tokenAddress).transfer(sendTo, amount);
    }

    /**
    @notice the function supposed to be used when governance voting implemented.
    @param _address is pool or vault address
    @param _description is brief info about the pool, optional
    @param _riskLevel personal contract will work with pools only if their risk level is more than this variable. 0-100%
    @param _approvedForStaticFunctions is true if strategist can call pre defined functions
    @param _approvedForDirectCallFunction is true if strategist can call any functions
    */
    function setAddressInfo(
        address _address, 
        string calldata _description, 
        uint256 _riskLevel, 
        bool _approvedForStaticFunctions, 
        bool _approvedForDirectCallFunction
    ) onlyOwner external {
        require(_address != address(0), 'Address is empty');
        addresses[_address] = AddressInfo(_description, _riskLevel, _approvedForStaticFunctions, _approvedForDirectCallFunction);
    }


    /**
    @notice used by personal contract. Static calls mean predefined number of functions. Strategist can not call custom transaction
    @notice it is safe to send riskLevel here, cause the function is called by contract
    @return true if prool is approved and client's riskLevel higher than the pool's one
    */
    function isAddressApprovedForStaticFunctions(address _address, uint256 riskLevel) view external returns (bool){
        return  skipApprove || (addresses[_address].approvedForStaticFunctions && addresses[_address].riskLevel <= riskLevel);
    }

    /**
    @notice used by personal contract. Direct calls mean that strategist can call any function with any parameters in the pool
    @notice it is safe to send riskLevel here, cause the function is called by contract
    @return true if prool is approved and client's riskLevel higher than the pool's one
    */
    function isAddressApprovedForDirectCallFunction(address _address, uint256 riskLevel) view external returns (bool){
        return  skipApprove || (addresses[_address].approvedForDirectCallFunction && addresses[_address].riskLevel <= riskLevel);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function generatePersonalContractEvent(string calldata _type, bytes calldata _data) external {
        require(personalContractsToUsers[msg.sender] != address(0), 'personal contracts only');
        emit PersonalContractEvent(personalContractsToUsers[msg.sender], msg.sender, _type, _data);
    }

    /**
    @notice deploy personal cont. https://blog.openzeppelin.com/deep-dive-into-the-minimal-proxy-contract/
    @return address of deployed personal lib
    */
    function clonePersonalLibrary() internal returns (address) {
        return deployMinimal(personalLibImplementation, "");
    }
    
    function() external payable {
        revert("Do not send ETH directly");
    }

}

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following 
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

pragma solidity ^0.5.2;

/**
 * @title Elliptic curve signature operations
 * @dev Based on https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
 * TODO Remove this library once solidity supports passing a signature to ecrecover.
 * See https://github.com/ethereum/solidity/issues/864
 *
 * Source https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-solidity/79dd498b16b957399f84b9aa7e720f98f9eb83e3/contracts/cryptography/ECDSA.sol
 * This contract is copied here and renamed from the original to avoid clashes in the compiled artifacts
 * when the user imports a zos-lib contract (that transitively causes this contract to be compiled and added to the
 * build/artifacts folder) as well as the vanilla implementation from an openzeppelin version.
 */

library OpenZeppelinUpgradesECDSA {
    /**
     * @dev Recover signer address from a message by using their signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param signature bytes signature, the signature is generated using web3.eth.sign()
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

        // If the signature is valid (and not malleable), return the signer address
        return ecrecover(hash, v, r, s);
    }

    /**
     * toEthSignedMessageHash
     * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
     * and hash the result
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

pragma solidity ^0.5.0;

import './UpgradeabilityProxy.sol';

/**
 * @title BaseAdminUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with an authorization
 * mechanism for administrative tasks.
 * All external functions in this contract must be guarded by the
 * `ifAdmin` modifier. See ethereum/solidity#3864 for a Solidity
 * feature proposal that would enable this to be done automatically.
 */
contract BaseAdminUpgradeabilityProxy is BaseUpgradeabilityProxy {
  /**
   * @dev Emitted when the administration has been transferred.
   * @param previousAdmin Address of the previous admin.
   * @param newAdmin Address of the new admin.
   */
  event AdminChanged(address previousAdmin, address newAdmin);

  /**
   * @dev Storage slot with the admin of the contract.
   * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
   * validated in the constructor.
   */

  bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

  /**
   * @dev Modifier to check whether the `msg.sender` is the admin.
   * If it is, it will run the function. Otherwise, it will delegate the call
   * to the implementation.
   */
  modifier ifAdmin() {
    if (msg.sender == _admin()) {
      _;
    } else {
      _fallback();
    }
  }

  /**
   * @return The address of the proxy admin.
   */
  function admin() external ifAdmin returns (address) {
    return _admin();
  }

  /**
   * @return The address of the implementation.
   */
  function implementation() external ifAdmin returns (address) {
    return _implementation();
  }

  /**
   * @dev Changes the admin of the proxy.
   * Only the current admin can call this function.
   * @param newAdmin Address to transfer proxy administration to.
   */
  function changeAdmin(address newAdmin) external ifAdmin {
    require(newAdmin != address(0), "Cannot change the admin of a proxy to the zero address");
    emit AdminChanged(_admin(), newAdmin);
    _setAdmin(newAdmin);
  }

  /**
   * @dev Upgrade the backing implementation of the proxy.
   * Only the admin can call this function.
   * @param newImplementation Address of the new implementation.
   */
  function upgradeTo(address newImplementation) external ifAdmin {
    _upgradeTo(newImplementation);
  }

  /**
   * @dev Upgrade the backing implementation of the proxy and call a function
   * on the new implementation.
   * This is useful to initialize the proxied contract.
   * @param newImplementation Address of the new implementation.
   * @param data Data to send as msg.data in the low level call.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   */
  function upgradeToAndCall(address newImplementation, bytes calldata data) payable external ifAdmin {
    _upgradeTo(newImplementation);
    (bool success,) = newImplementation.delegatecall(data);
    require(success);
  }

  /**
   * @return The admin slot.
   */
  function _admin() internal view returns (address adm) {
    bytes32 slot = ADMIN_SLOT;
    assembly {
      adm := sload(slot)
    }
  }

  /**
   * @dev Sets the address of the proxy admin.
   * @param newAdmin Address of the new proxy admin.
   */
  function _setAdmin(address newAdmin) internal {
    bytes32 slot = ADMIN_SLOT;

    assembly {
      sstore(slot, newAdmin)
    }
  }

  /**
   * @dev Only fall back when the sender is not the admin.
   */
  function _willFallback() internal {
    require(msg.sender != _admin(), "Cannot call fallback function from the proxy admin");
    super._willFallback();
  }
}

pragma solidity ^0.5.0;

import './Proxy.sol';
import '../utils/Address.sol';

/**
 * @title BaseUpgradeabilityProxy
 * @dev This contract implements a proxy that allows to change the
 * implementation address to which it will delegate.
 * Such a change is called an implementation upgrade.
 */
contract BaseUpgradeabilityProxy is Proxy {
  /**
   * @dev Emitted when the implementation is upgraded.
   * @param implementation Address of the new implementation.
   */
  event Upgraded(address indexed implementation);

  /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  /**
   * @dev Returns the current implementation.
   * @return Address of the current implementation
   */
  function _implementation() internal view returns (address impl) {
    bytes32 slot = IMPLEMENTATION_SLOT;
    assembly {
      impl := sload(slot)
    }
  }

  /**
   * @dev Upgrades the proxy to a new implementation.
   * @param newImplementation Address of the new implementation.
   */
  function _upgradeTo(address newImplementation) internal {
    _setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }

  /**
   * @dev Sets the implementation address of the proxy.
   * @param newImplementation Address of the new implementation.
   */
  function _setImplementation(address newImplementation) internal {
    require(OpenZeppelinUpgradesAddress.isContract(newImplementation), "Cannot set a proxy implementation to a non-contract address");

    bytes32 slot = IMPLEMENTATION_SLOT;

    assembly {
      sstore(slot, newImplementation)
    }
  }
}

pragma solidity ^0.5.0;

import './BaseAdminUpgradeabilityProxy.sol';
import './InitializableUpgradeabilityProxy.sol';

/**
 * @title InitializableAdminUpgradeabilityProxy
 * @dev Extends from BaseAdminUpgradeabilityProxy with an initializer for 
 * initializing the implementation, admin, and init data.
 */
contract InitializableAdminUpgradeabilityProxy is BaseAdminUpgradeabilityProxy, InitializableUpgradeabilityProxy {
  /**
   * Contract initializer.
   * @param _logic address of the initial implementation.
   * @param _admin Address of the proxy administrator.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  function initialize(address _logic, address _admin, bytes memory _data) public payable {
    require(_implementation() == address(0));
    InitializableUpgradeabilityProxy.initialize(_logic, _data);
    assert(ADMIN_SLOT == bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1));
    _setAdmin(_admin);
  }
}

pragma solidity ^0.5.0;

import './BaseUpgradeabilityProxy.sol';

/**
 * @title InitializableUpgradeabilityProxy
 * @dev Extends BaseUpgradeabilityProxy with an initializer for initializing
 * implementation and init data.
 */
contract InitializableUpgradeabilityProxy is BaseUpgradeabilityProxy {
  /**
   * @dev Contract initializer.
   * @param _logic Address of the initial implementation.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  function initialize(address _logic, bytes memory _data) public payable {
    require(_implementation() == address(0));
    assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1));
    _setImplementation(_logic);
    if(_data.length > 0) {
      (bool success,) = _logic.delegatecall(_data);
      require(success);
    }
  }  
}

pragma solidity ^0.5.0;

/**
 * @title Proxy
 * @dev Implements delegation of calls to other contracts, with proper
 * forwarding of return values and bubbling of failures.
 * It defines a fallback function that delegates all calls to the address
 * returned by the abstract _implementation() internal function.
 */
contract Proxy {
  /**
   * @dev Fallback function.
   * Implemented entirely in `_fallback`.
   */
  function () payable external {
    _fallback();
  }

  /**
   * @return The Address of the implementation.
   */
  function _implementation() internal view returns (address);

  /**
   * @dev Delegates execution to an implementation contract.
   * This is a low level function that doesn't return to its internal call site.
   * It will return to the external caller whatever the implementation returns.
   * @param implementation Address to delegate.
   */
  function _delegate(address implementation) internal {
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize)

      // Call the implementation.
      // out and outsize are 0 because we don't know the size yet.
      let result := delegatecall(gas, implementation, 0, calldatasize, 0, 0)

      // Copy the returned data.
      returndatacopy(0, 0, returndatasize)

      switch result
      // delegatecall returns 0 on error.
      case 0 { revert(0, returndatasize) }
      default { return(0, returndatasize) }
    }
  }

  /**
   * @dev Function that is run as the first thing in the fallback function.
   * Can be redefined in derived contracts to add functionality.
   * Redefinitions must call super._willFallback().
   */
  function _willFallback() internal {
  }

  /**
   * @dev fallback implementation.
   * Extracted to enable manual triggering.
   */
  function _fallback() internal {
    _willFallback();
    _delegate(_implementation());
  }
}

pragma solidity ^0.5.3;

import "./InitializableAdminUpgradeabilityProxy.sol";
import "../cryptography/ECDSA.sol";

contract ProxyFactory {
  
  event ProxyCreated(address proxy);

  bytes32 private contractCodeHash;

  constructor() public {
    contractCodeHash = keccak256(
      type(InitializableAdminUpgradeabilityProxy).creationCode
    );
  }

  function deployMinimal(address _logic, bytes memory _data) public returns (address proxy) {
    // Adapted from https://github.com/optionality/clone-factory/blob/32782f82dfc5a00d103a7e61a17a5dedbd1e8e9d/contracts/CloneFactory.sol
    bytes20 targetBytes = bytes20(_logic);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      proxy := create(0, clone, 0x37)
    }
    
    emit ProxyCreated(address(proxy));

    if(_data.length > 0) {
      (bool success,) = proxy.call(_data);
      require(success);
    }    
  }

  function deploy(uint256 _salt, address _logic, address _admin, bytes memory _data) public returns (address) {
    return _deployProxy(_salt, _logic, _admin, _data, msg.sender);
  }

  function deploySigned(uint256 _salt, address _logic, address _admin, bytes memory _data, bytes memory _signature) public returns (address) {
    address signer = getSigner(_salt, _logic, _admin, _data, _signature);
    require(signer != address(0), "Invalid signature");
    return _deployProxy(_salt, _logic, _admin, _data, signer);
  }

  function getDeploymentAddress(uint256 _salt, address _sender) public view returns (address) {
    // Adapted from https://github.com/archanova/solidity/blob/08f8f6bedc6e71c24758d20219b7d0749d75919d/contracts/contractCreator/ContractCreator.sol
    bytes32 salt = _getSalt(_salt, _sender);
    bytes32 rawAddress = keccak256(
      abi.encodePacked(
        bytes1(0xff),
        address(this),
        salt,
        contractCodeHash
      )
    );

    return address(bytes20(rawAddress << 96));
  }

  function getSigner(uint256 _salt, address _logic, address _admin, bytes memory _data, bytes memory _signature) public view returns (address) {
    bytes32 msgHash = OpenZeppelinUpgradesECDSA.toEthSignedMessageHash(
      keccak256(
        abi.encodePacked(
          _salt, _logic, _admin, _data, address(this)
        )
      )
    );

    return OpenZeppelinUpgradesECDSA.recover(msgHash, _signature);
  }

  function _deployProxy(uint256 _salt, address _logic, address _admin, bytes memory _data, address _sender) internal returns (address) {
    InitializableAdminUpgradeabilityProxy proxy = _createProxy(_salt, _sender);
    emit ProxyCreated(address(proxy));
    proxy.initialize(_logic, _admin, _data);
    return address(proxy);
  }

  function _createProxy(uint256 _salt, address _sender) internal returns (InitializableAdminUpgradeabilityProxy) {
    address payable addr;
    bytes memory code = type(InitializableAdminUpgradeabilityProxy).creationCode;
    bytes32 salt = _getSalt(_salt, _sender);

    assembly {
      addr := create2(0, add(code, 0x20), mload(code), salt)
      if iszero(extcodesize(addr)) {
        revert(0, 0)
      }
    }

    return InitializableAdminUpgradeabilityProxy(addr);
  }

  function _getSalt(uint256 _salt, address _sender) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_salt, _sender)); 
  }
}

pragma solidity ^0.5.0;

import './BaseUpgradeabilityProxy.sol';

/**
 * @title UpgradeabilityProxy
 * @dev Extends BaseUpgradeabilityProxy with a constructor for initializing
 * implementation and init data.
 */
contract UpgradeabilityProxy is BaseUpgradeabilityProxy {
  /**
   * @dev Contract constructor.
   * @param _logic Address of the initial implementation.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  constructor(address _logic, bytes memory _data) public payable {
    assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1));
    _setImplementation(_logic);
    if(_data.length > 0) {
      (bool success,) = _logic.delegatecall(_data);
      require(success);
    }
  }  
}

pragma solidity ^0.5.0;

/**
 * Utility library of inline functions on addresses
 *
 * Source https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-solidity/v2.1.3/contracts/utils/Address.sol
 * This contract is copied here and renamed from the original to avoid clashes in the compiled artifacts
 * when the user imports a zos-lib contract (that transitively causes this contract to be compiled and added to the
 * build/artifacts folder) as well as the vanilla Address implementation from an openzeppelin version.
 */
library OpenZeppelinUpgradesAddress {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

