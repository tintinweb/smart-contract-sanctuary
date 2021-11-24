// SPDX-License-Identifier: GPLv2
pragma solidity 0.8.9;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
//import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
//import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "./PersonalLibraryProxy.sol";

interface IPersonal {
    function initialize(
        address payable _investor, 
        address _strategist, 
        uint256 _riskLevel,
        address _networkNativeToken,
        address _yieldToken,
        address _investmentTrackIn
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
    
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external payable returns (uint[] memory amounts);
}

interface IWBNBWETH {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
}
//TODO: improve upgradeable, use https://www.trufflesuite.com/blog/a-sweet-upgradeable-contract-experience-with-openzeppelin-and-truffle
//if any factory code update required !keep! variables order: https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable
contract Factory is OwnableUpgradeable, ReentrancyGuardUpgradeable {
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
    address[] strategies;
    mapping (address => AddressInfo) public addresses;
    mapping (address => address[]) public personalContracts;//user address => personal contracts address
    mapping (address => address) public personalContractsToUsers;//personal contract => user address
    mapping (address => uint256) public tokenToExchangeIndex;//token address => exchange index (in exchanges array)

    uint256 public onRewardNativeDevelopmentFund;
    uint256 public onRewardNativeBurn;
    uint256 public onRewardYieldDevelopmentFund;
    uint256 public onRewardYieldBurn;
    address public developmentFund;//this address collects developmentFund
    address public personalLibImplementation;
    address public tokenConversionLibrary;
    address public networkNativeToken;//WETH or WBNB
    address public yieldToken;
    address public yieldTokenPair;//BUSD for example. (not lp) This is in case it is not networkNative and we have to do extra swap; 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56
    address public investmentTrackIn;//BUSD for example. this is for personal contract, token to keep track investments amount

    //stake rewards options (will be used in PersonalLibrary, stakeReward function)
    uint256 public yieldStakeExchange;
    address public yieldStakeContract;
    uint256 public yieldStakeStrategy;
    address public yieldStakePair;
    uint256 public yieldStakePid;
    uint256 public yieldStakeLockSeconds;
    address public yieldStakeRewardToken;

    bool public skipApprove;
        
    event PersonalContractCreated(
        address _investorAddress, 
        address personalContractAddress, 
        address tokenToInvest, 
        uint256 riskLevel, 
        uint256 strategistEth,
        uint256 stopLossFull,
        uint256 stopLossTrailing
    );
    event PersonalContractEvent(address _investorAddress, address personalContractAddress, string eventType, bytes data);
    event newExchangeAdded(string name, address _in, address _out);

    constructor (
        address _developmentFund,
        address _personalLibImplementation,
        address _networkNativeToken,
        address _yieldToken,
        address _yieldTokenPair,
        address _tokenConversionLibrary,
        address _investmentTrackIn
    ) {
        initialize(
            _developmentFund, 
            _personalLibImplementation, 
            _networkNativeToken, 
            _yieldToken, 
            _yieldTokenPair, 
            _tokenConversionLibrary, 
            _investmentTrackIn
        );
    }

    function initialize(
        address _developmentFund,
        address _personalLibImplementation,
        address _networkNativeToken,
        address _yieldToken,
        address _yieldTokenPair,
        address _tokenConversionLibrary,
        address _investmentTrackIn
    ) public {
        __Ownable_init();
        //__ReentrancyGuard_init_unchained();

        require(personalLibImplementation == address(0), 'already initialized');
    
        require(_developmentFund != address(0), '_developmentFund is empty');
        require(_personalLibImplementation != address(0), '_personalLibImplementation is empty');
        require(_networkNativeToken != address(0), '_networkNativeToken is empty');
        require(_yieldToken != address(0), '_yieldToken is empty');
        require(_tokenConversionLibrary != address(0), '_tokenConversionLibrary is empty');

        developmentFund = _developmentFund;
        networkNativeToken = _networkNativeToken;
        yieldToken = _yieldToken;
        yieldTokenPair = _yieldTokenPair;
        personalLibImplementation = _personalLibImplementation;
        tokenConversionLibrary = _tokenConversionLibrary;
        investmentTrackIn = _investmentTrackIn;

        //example of pre-approved addresses
        //addresses[0xeaB819E2BE63FFC0dF64E7BBA4DDB3bDEa280310] = AddressInfo('Pancake:BUSD-BNB', 25, true, true);
        //addresses[0x221ED06024Ee4296fB544a44cfEDDf7c9f882cF3] = AddressInfo('Pancake:ETH-BNB', 55, true, true);


        //exchanges.push(Exchange('', address(0), address(0)));//hardcoded reminder to skip index 0

        //owner = msg.sender;

        //example of pre-defined exhanges
        //exchanges.push(Exchange('PancakeswapV2', 0xe40d348D677530b5692150Fe6C98bb06749723E4, 0x2C501Ac9271b2Dc3D14A152979aE7B32ED0BeE7C));

        onRewardNativeDevelopmentFund = 500;//5.00%
        onRewardNativeBurn = 500;//5.00%
        onRewardYieldDevelopmentFund = 250;//2.50%
        onRewardYieldBurn = 250;//2.50%
        skipApprove = true;//set true if there is no appropriate pool approval functionality implemented

        exchanges.push(Exchange('', address(0), address(0)));//hardcoded reminder to skip index 0
        exchanges.push(Exchange('PancakeswapV1', 0xe40d348D677530b5692150Fe6C98bb06749723E4, 0x2C501Ac9271b2Dc3D14A152979aE7B32ED0BeE7C));
        exchanges.push(Exchange('PancakeswapV2', 0xff435e69eE005f9aeAf9c3410605Da9f2B21B796, 0x0612B63dcbAeDD02ea9d5dc61Bb54d3722D4Ef80));
        exchanges.push(Exchange('Apeswap', 0x7fA14739a444Fa979fBF32a7cB675f1a8Cd5E186, 0xA25b065D8c4465858D625853924DeBd946a0e85B));
        exchanges.push(Exchange('SushiswapBSC', 0xFA8b1E26B7505e1fC06EB31476a752F2454BA616, 0x497e1CdF2Bd3C60196dfCf106c2b4B12427f45F7));
        exchanges.push(Exchange('Cafeswap', 0xE9C23Ab1C09ACd5902675D11fD30E6Eb52514dD9, 0xF6049Aae2cC4E425a14dec4F061931C4388982f3));
        exchanges.push(Exchange('Palmswap', 0x77af866513C192d582fce14114A8B33e713B5260, 0x030568D6a6723f0AbC3aa537190388a34911F1c4));
        /*exchanges.push(Exchange('Bakeryswap', 0x904277f952f4D033A9A1de2fA5DE79a165FbeC2E, 0x6759479900B952962a25b95ec059a7Ac6248F754));
        exchanges.push(Exchange('Jetswap', 0x64F5Ef28102d52fb45857D2f7397D23B9E58439C, 0x5262BCFD90Dd098bcBEE3C08B305bf11B79cEE6A));
        exchanges.push(Exchange('Thunderswap', 0x2559e1e8128F62fB207bCCA9a0f07a58921719f3, 0x5BaA9F34bDa51B212b06b9D07af22b9762eE1AE4));
        exchanges.push(Exchange('Kebab', 0x9e364a8aC4C25Ff03BB505070DcCE693Ea2Bc95B, 0x95B751B2D6142Bca1037009ecdA20799465d9813));
        exchanges.push(Exchange('Mdex', 0x18883853028b8c6430d3B0436EffF472817A4345, 0x2cED2c96D9E47aD55d5d082Fb0F40B8a50D4159F));
        exchanges.push(Exchange('WaultSwap', 0x57b3fc2a109434f457f7aeB367c29Cd6c5d8AD63, 0x6a94cDAf47cC289f5bD878ee70b835F908d2de29));
        exchanges.push(Exchange('BSCswap', 0x5167449Ea455a8DeAA3EeC0650f71e5Ea3d06853, 0xb84705EBb8503ee7C287c3BB90B1A54BaC6Cc0b9));
        exchanges.push(Exchange('Valuedefi', 0x1d42beF1C8AFc39c922593E126c8E39ec9ED7133, 0xFE8f34889832fECc1eABdbD489843B446B631d54));
        exchanges.push(Exchange('Slimeswap', 0xAa21982F91140139Dc35810097af926d8385674F, 0xFFD22F199d6e8e18d86fD363dfE6491ca91DAe13));
        exchanges.push(Exchange('UniswapBSC', 0x05Cb1527d49305E2226C235893eD5991b7d91dD5, 0x10bda135D568690b22B288007906403FcC663422));
        exchanges.push(Exchange('PokemoonSwap', 0x2496112Ed1E84ee1Ea59d41AB7F0E262F64D9EDC, 0x328ccdddf9BBcA1314DDeE3289308A9cf7b1242f));
        exchanges.push(Exchange('SwipeSwap', 0x47C884a94fd0Cd919e45b1d914fA2E6fEA4276Ec, 0x0f575f8aAf10fcd66808535596e2e0C0585033f4));*/
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
        uint256[] memory _stopLoss,
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
            _stopLoss,
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
        uint256[] memory _stopLoss,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) nonReentrant payable external returns (address) {
        return _createPersonalContract(
            payable(msg.sender), 
            _strategistAddress, 
            _strategistEth, 
            _tokenToInvest,
            _amountToPersonalContract,
            _amountToStrategist,
            _riskLevel,
            _stopLoss,
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
        uint256 _riskLevel,
        uint256[] memory _stopLoss
    ) nonReentrant payable external returns (address) {
        return _createPersonalContract(
            payable(msg.sender), 
            _strategistAddress, 
            _strategistEth, 
            _tokenToInvest,
            _amountToPersonalContract,
            _amountToStrategist,
            _riskLevel,
            _stopLoss,
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
    @param _stopLoss [0] - regular stop loss, [1] - trailing stop loss. this is for back end only, no validation, no use in contract
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
        uint256[] memory _stopLoss,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) internal returns (address) {
        require(_investorAddress != address(0), 'EMPTY_INVESTOR_ADDRESS');
        //require(personalContracts[_investorAddress] == address(0), 'CONTRACT_EXISTS');

        //address payable personalContractAddress = payable(ClonesUpgradeable.clone(personalLibImplementation));
        //address payable personalContractAddress = payable(new BeaconProxy(address(this), ""));
        address payable personalContractAddress = payable(new PersonalLibraryProxy());

        require(personalContractAddress != address(0), 'personalContractAddress is 0x00..');

        IPersonal(personalContractAddress).initialize(
            _investorAddress, 
            _strategistAddress, 
            _riskLevel, 
            networkNativeToken, 
            yieldToken, 
            investmentTrackIn
        );
        personalContracts[_investorAddress].push(personalContractAddress);
        personalContractsToUsers[personalContractAddress] = _investorAddress;

        if(msg.value > 0){
            if(_strategistEth > 0){
                require(_strategistEth <= msg.value, '_strategistEth > msg.value');
                _strategistAddress.transfer(_strategistEth);   
            }
            //personalContractAddress.transfer(msg.value.sub(_strategistEth));
            if(msg.value - _strategistEth > 0){
                //it's ok if no investment to personal contract. it could be sent later
                sendValue(personalContractAddress, msg.value - _strategistEth);
            }
        }
        if(address(_tokenToInvest) != address(0)){

            if(v > 0){//permittable token 
                IERC20Permit(_tokenToInvest).permit(
                    msg.sender, 
                    address(this), 
                    _amountToPersonalContract + _amountToStrategist, 
                     type(uint128).max, 
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
                //TODO: add min tokens variable instead of 1. Search key mintokn1024
                //this is low priority, we don't work with tokens yet from front end
                
                //uint256 strategistBefore1 = address(_strategistAddress).balance;
                //uint256 strategistBefore2 = IERC20(networkNativeToken).balanceOf(_strategistAddress);
                convertTokenToETH(_strategistAddress, _tokenToInvest, _amountToStrategist, 1);
                /*require(
                    IERC20(networkNativeToken).balanceOf(_strategistAddress) > strategistBefore2 || 
                    address(_strategistAddress).balance > strategistBefore1,
                    "yep, found the error"
                );*/
            }

        }

        emit PersonalContractCreated(
            _investorAddress, 
            personalContractAddress, 
            _tokenToInvest, 
            _riskLevel, 
            _strategistEth, 
            _stopLoss[0], 
            _stopLoss[1]
        );
        return personalContractAddress;
    }

    /**
    @notice Convert tokens to eth or wbnb
    @param _toWhomToIssue is address of personal contract for this user
    @param _tokenToExchange address of token witch will be converted
    @param _amount how much will be converted
    */
    function convertTokenToETH(address _toWhomToIssue, address _tokenToExchange, uint256 _amount, uint256 _minOutputAmount) internal {

        //TODO: figure out why we can't use tokenConversionLibrary library here. 
        //if uncomment, no error, but eth wasn't sent, not sure why
        //so, I use direct ITokenExchangeRouter request
        /*bool status;
        (status,) = tokenConversionLibrary.delegatecall(abi.encodeWithSignature(
            "convertTokenToETH(address,address,address,uint256,uint256)",  
            address(this),
            _toWhomToIssue, 
            _tokenToExchange, 
            _amount, 
            _minOutputAmount
        ));
        require(status, 'convertTokenToETH call failed');*/


        (, address router, address[] memory path) = checkIfTokensCanBeExchangedWith1Exchange(_tokenToExchange, networkNativeToken);
        IERC20(_tokenToExchange).approve(router, _amount);
        ITokenExchangeRouter(router).swapExactTokensForETH(
            _amount,
            _minOutputAmount,
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

        require(routerIndex1 > 0 && routerIndex2 > 0, 'no router index defined');

        bool isThereNetworkNative = (_token1 == networkNativeToken || _token2 == networkNativeToken);
        bool isThereYieldToken = (_token1 == yieldToken || _token2 == yieldToken);
        bool extraStepForYield = (yieldTokenPair != address(0) && yieldTokenPair != networkNativeToken);

        bool same = (routerIndex1 == routerIndex2 || isThereNetworkNative);


        /*if(!same){
            // check maybe there is the first token is on the second tokens pool (or vice versa)
            //if so, set same = true and routers = to the new common.
        }*/

        if(same){

            address[] memory path;
            uint256 routerIndex;
            if(isThereNetworkNative && isThereYieldToken && extraStepForYield){
                routerIndex = _token1 == yieldToken ? routerIndex1:routerIndex2;
                path = new address[](3);
                path[0] = _token1;
                path[1] = yieldTokenPair;//in cause no WBNB for YIELD
                path[2] = _token2;
                return (true, YZap(exchanges[routerIndex].inContractAddress).routerAddress(), path);
            }

            if(!isThereYieldToken || !extraStepForYield){
                uint256 length = isThereNetworkNative?2:3;
                path = new address[](length);

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

            path = new address[](4);
            path[0] = _token1;
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
    @notice similar to openzeppelin's upgradeTo function (of upgradeableBeacon.sol)
    @param _implementation address of personal lib
    */
    function setPersonalLibImplementation(address _implementation) onlyOwner external {
        require(_implementation != address(0));
        personalLibImplementation = _implementation;
    }

    /**
    @notice allows set different token conversion logic.
    @param _tokenConversionLibrary address of new logic
    */
    function setTokenConversionLibrary(address _tokenConversionLibrary) onlyOwner external {
        require(_tokenConversionLibrary != address(0));
        tokenConversionLibrary = _tokenConversionLibrary;
    }

    /**
    @notice function to get personal library implementation
    @notice similar to openzeppelin's implementation function (of upgradeableBeacon.sol)
    */
    function implementation() public view returns (address) {
        return personalLibImplementation;
    }

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
    @notice the require here to avoid staking into 0 address
    @param _index index in strategies array
    */
    function getStrategy(uint256 _index) external view returns(address) {
        require(strategies[_index] != address(0), 'the strategy not yet deployed');
        return strategies[_index];
    }
        
    /**
    @param _index add/update index in strategies array
    @param _strategy address of deployed strategy
    */
    function setStrategy(uint256 _index, address _strategy) onlyOwner external {
        require(_strategy != address(0), 'set: empty strategy address');
        strategies[_index] = _strategy;
    }
        
    /**
    @param _strategy address of deployed strategy
    */
    function addStrategy(address _strategy) onlyOwner external {
        require(_strategy != address(0), 'add: empty strategy address');
        strategies.push(_strategy);
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
    @notice will be used by back end / front end to build correct flow
    @return flow that this contracts works
    */
    function version() pure external returns (uint256){
        return 5;
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
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function generatePersonalContractEvent(string calldata _type, bytes calldata _data) external {
        require(personalContractsToUsers[msg.sender] != address(0), 'personal contracts only');
        emit PersonalContractEvent(personalContractsToUsers[msg.sender], msg.sender, _type, _data);
    }
    
    receive() external payable {
        revert("Do not send ETH directly");
    }

}

// SPDX-License-Identifier: GPLv2
pragma solidity 0.8.9;
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

//contract for etherscan, bscscan, polygonscan, etc... 
//to be able to verify as proxy 
contract PersonalLibraryProxy is BeaconProxy {
    constructor() BeaconProxy(msg.sender, ""){}
    function implementation() external view returns (address) {
        return _implementation();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../Proxy.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from a {UpgradeableBeacon}.
 *
 * The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
 * conflict with the storage layout of the implementation behind the proxy.
 *
 * _Available since v3.4._
 */
contract BeaconProxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializating the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */
    constructor(address beacon, bytes memory data) payable {
        assert(_BEACON_SLOT == bytes32(uint256(keccak256("eip1967.proxy.beacon")) - 1));
        _upgradeBeaconToAndCall(beacon, data, false);
    }

    /**
     * @dev Returns the current beacon address.
     */
    function _beacon() internal view virtual returns (address) {
        return _getBeacon();
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation() internal view virtual override returns (address) {
        return IBeacon(_getBeacon()).implementation();
    }

    /**
     * @dev Changes the proxy to use a new beacon. Deprecated: see {_upgradeBeaconToAndCall}.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon.
     *
     * Requirements:
     *
     * - `beacon` must be a contract.
     * - The implementation returned by `beacon` must be a contract.
     */
    function _setBeacon(address beacon, bytes memory data) internal virtual {
        _upgradeBeaconToAndCall(beacon, data, false);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlot.BooleanSlot storage rollbackTesting = StorageSlot.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            Address.functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
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
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}