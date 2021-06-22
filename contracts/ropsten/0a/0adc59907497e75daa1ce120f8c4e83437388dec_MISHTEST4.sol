/**
 *Submitted for verification at Etherscan.io on 2021-06-22
*/

/**


SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

contract MISHTEST4 is Context, IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = "MISHKTEST4";
    string private constant _symbol = "MISHTEST4";
    uint8 private constant _decimals = 9;
    mapping(address => bool) private bots;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private constant MAX = ~uint256(0);
    uint256 private  _tTotal = 1000000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 private _dynamicFee = 1;
    mapping(address => uint256) private buycooldown;
    address private _marketingAddress;
    address private _charityAddress;
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen = false;
    bool private liquidityAdded = false;
    bool private inSwap = false;
    bool private swapEnabled = false;
    uint256 private _coolDownSeconds = 30;
    uint256 private _maxTxBasis = 300;
    bool private _takeFee = true;

    event MaxTxBasisUpdated(uint256 _maxTxBasis);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    
    constructor () {
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _rOwned[_msgSender()] = _rTotal;
        
        // Bot Blacklist
        bots[address(0xE031b36b53E53a292a20c5F08fd1658CDdf74fce)] = true;
        bots[address(0xE031b36b53E53a292a20c5F08fd1658CDdf74fce)] = true;
        bots[address(0xa1ceC245c456dD1bd9F2815a6955fEf44Eb4191b)] = true;
        bots[address(0xe516bDeE55b0b4e9bAcaF6285130De15589B1345)] = true;
        bots[address(0xd7d3EE77D35D0a56F91542D4905b1a2b1CD7cF95)] = true;
        bots[address(0xFe76f05dc59fEC04184fA0245AD0C3CF9a57b964)] = true;
        bots[address(0xDC81a3450817A58D00f45C86d0368290088db848)] = true;
        bots[address(0x45fD07C63e5c316540F14b2002B085aEE78E3881)] = true;
        bots[address(0x27F9Adb26D532a41D97e00206114e429ad58c679)] = true;
        bots[address(0xE8dd4e0a2aF9a8570Ea6814086A5B2D64d1027fc)] = true;
        bots[address(0x925D29bA52c251Ff07F1EEeC994255e90cCa5b32)] = true;
        bots[address(0xF9F653cF0334460a0355e98E60dEA7Ab95ca2bb2)] = true;
        bots[address(0xd2143B88B098bFe433292D90d8AA13dC0f58f69a)] = true;
        bots[address(0x4f5638087e136f9c83111f2e4a4d7C39bab150C1)] = true;
        bots[address(0x144CA224eDF9478686f0094CE267f30736fDFe1b)] = true;
        bots[address(0x899c4ECdd572Aa809f7d2dd6252D1F6C422f733E)] = true;
        bots[address(0x9cC5F1f67813e484c08fcCDC32c4B9089c4C8807)] = true;
        bots[address(0xe84b8C42eC24F45533c3572F2781eFa79D30Fb47)] = true;
        bots[address(0xDE74c1c979A31c80562f0B893b250B4d9AD6B510)] = true;
        bots[address(0x934f6aeebc457679fBb2A046A6eD886e2beAD8b4)] = true;
        bots[address(0x2b9fd1AB83DA6D0Bc8255Ea1d5608c9FE2E6DAA3)] = true;
        bots[address(0x4A6baC82122dd05C5DFfADff60F4F3fE51d5a453)] = true;
        bots[address(0x41e6575C31AD8915Ff8cE5aDd7ce265c2b6C5d3C)] = true;
        bots[address(0x10c70D9Cffe5414204D07912dC89E34A13e4210F)] = true;
        bots[address(0x9914996830Ce1176aEb7513c1323ee1adbCFbf8E)] = true;
        bots[address(0x0FD1C6C33117Aef1FFd0779B5fCD114385075446)] = true;
        bots[address(0x09e09bd3B884Da1e115c27Ae719Fff52AF1b3769)] = true;
        bots[address(0x1EF04Fd7CF27Eed18fc34e8902d3cC68Cc7012A8)] = true;
        bots[address(0x511F00C4A0b9Cf6E464B39cA8C4Db3d90E0e41a6)] = true;
        bots[address(0xaEda57d9D1353fAC2609738a553639cE58E9ee9b)] = true;
        bots[address(0x5f175c2602856DeCcc9f610519EF65707dc7190a)] = true;
        bots[address(0x081fFB021d5076040E39d891A01abAaB0fFb192b)] = true;
        bots[address(0x67851af7920206006Ae0Eef3bBB445C91C39938c)] = true;
        bots[address(0xE4369BE6dF50Aa406DB8212Ae00CF81917C848ea)] = true;
        bots[address(0xC6bF34596f74eb22e066a878848DfB9fC1CF4C65)] = true;
        bots[address(0x54a4E00fFa3a45a639A1211aC16A87fB2Ac1FC13)] = true;
        bots[address(0x9bc9223112027A1A6cF1f893C0f5c0c7399d8Ecd)] = true;
        bots[address(0xDC095f76B3A3d66421248234d2546c0d9570C8C1)] = true;
        bots[address(0x82412969100a310C006E865F5e4369EfEa8272F7)] = true;
        bots[address(0xaaC3612F3598A30D40ce0FCA1F0287D09fe91479)] = true;
        bots[address(0xbd6663196546DC4d4Ec32BAB3286E937D3c44cA0)] = true;
        bots[address(0xb81791FEb4E0342064cf4Ef52f05d02b1689ACE7)] = true;
        bots[address(0x2D13f310f95c727b8e77C52937bA5c697c5f2A3f)] = true;
        bots[address(0xb03285A1Cf1A51FD03892d56B6235A18e2F7E363)] = true;
        bots[address(0x36e65ADDAa46D421EE698de7E6EF5a1D714F9658)] = true;
        bots[address(0xBFdC7b80a3284AFF57c045806A3b99Ad446450A2)] = true;
        bots[address(0xfd72c4bF172aC676ddd713f538254b6AC1422B06)] = true;
        bots[address(0x34b2B5b28314FBa4a1FbA3Fe1a7Fdd2f71A32Ba8)] = true;
        bots[address(0x77aaA9AcFf4d04020aF51f1e1f9e31746a7a4866)] = true;
        bots[address(0xefe7ee018d862cC1C0D0aDb26e73Fb90D6C1195D)] = true;
        bots[address(0x9D8069F0594cAE7200cB2b8233145AB08ED52920)] = true;
        bots[address(0xC92A13FA4C59f5349B4d45E8667547D8419F0906)] = true;
        bots[address(0xF5637Bfc651A33b4ecc10826F89839e564A41443)] = true;
        bots[address(0x2d0E64B6bF13660a4c0De42a0B88144a7C10991F)] = true;
        bots[address(0x2D56342EE9ea16711C84CB9d23f23e4A6d3082DB)] = true;
        bots[address(0xc7E3E70793630a779c2b0cF15ce4de7f435D27c9)] = true;
        bots[address(0xd4C09d7c8d0c144baA8c8C5d1F0F7E1130C7A4Ed)] = true;
        bots[address(0xd75820833c8FF49dabEE75CC6cf0b5f4b4c41FD1)] = true;
        bots[address(0x9592B3DDa4d168626FCc43A6E933963eeB48De45)] = true;
        bots[address(0xa0A1520354c78bbE5868FE2dA7A617f08A9D1A88)] = true;
        bots[address(0xe31B79E9b326d65b2cC8DC0639d261EaF2CD2da2)] = true;
        bots[address(0x05a13169C9349Afa15B168B6aacbE484028E66f1)] = true;
        bots[address(0x3B5B4B363cFc039E81B16Cc08E332ab64063e3C3)] = true;
        bots[address(0x6cCD3bee114e4E8E9A9dA9b720E5AFE00a559774)] = true;
        bots[address(0x87AF93bc06bb926523160b0aD1E3b50544928D76)] = true;
        bots[address(0xb44c96F766355624eeaFECE1285b808E69F4Ee63)] = true;
        bots[address(0xf86ff5E3F6842CB717cAc312166945e88E100514)] = true;
        bots[address(0x2Aa3059a5754ac069740F1924cB44c944eF568E4)] = true;
        bots[address(0x5c99f913d3e600e26941218Fa3e1B87505D47492)] = true;
        bots[address(0xa725Af04f093e20B645Cd81cEDCbA224665F66ac)] = true;
        bots[address(0x59CDD910905F706B9dEbB10dC09cdC42d7F47B56)] = true;
        bots[address(0x4CC04e7fDd5316a6873DFB945F0208F4e7d5823f)] = true;
        bots[address(0xf8e664ea169422DA06e6D96Cb576AC2866F97072)] = true;
        bots[address(0xBC009036d8Ca3B9d317D23283F41C58956a5875D)] = true;
        bots[address(0x40430074c133e1cF40c6eE4d14c97cB55Fd3c0a5)] = true;
        bots[address(0xd7444eb48CE71F2D75dA56344dE8265F18F2c045)] = true;
        bots[address(0xC6B02A8034Ee8FBd4D0aB970a0B231510A470A45)] = true;
        bots[address(0xc2eA7561062cf5ECB1DB4C0d58Ea77D20bFa5197)] = true;
        bots[address(0x26a51444BC39a588B26aB9C273427fbB7e1Cd06c)] = true;
        bots[address(0xF700084b07BabD4cf44765Da5A31eBBd2A63b680)] = true;
        bots[address(0x3dfb83F5B16f932FdcBbE70AF088698Fb58B3880)] = true;
        bots[address(0x5b39e1563F0eD7e4673ee8855d1de1bB891d9B15)] = true;
        bots[address(0x468cB54a3821d8b0129C42Ea6ADf12748d97fD98)] = true;
        bots[address(0x8226fA48E86B64097fBf0417E7d61B503EFB0963)] = true;
        bots[address(0xE61eB661Ad2aDD6F8e8B1E1a065Be3885b4Dac5a)] = true;
        bots[address(0xD08734dE7cc4f2e8eAD5F4b20b12E4234718410f)] = true;
        bots[address(0xe419bC78D80a3689DFF874e83CC2e3E9aA822F7e)] = true;
        bots[address(0x8467Db1899f5Ca971Ec1e08c2E8759a6D449d4Fb)] = true;
        bots[address(0xD5d9B7CbF5C5a8b750492d2746c8Af6dAD972Cf2)] = true;
        bots[address(0xd4a0c19b4130805edA5Cc378CdCC4b60f1f178Ec)] = true;
        bots[address(0x30e8d77ADFbc1D446aFdb5338828280bd323Fa86)] = true;
        bots[address(0x289001a2fAcF539f444A28548B563f57Ba7362bD)] = true;
        bots[address(0xD15EfD7C8cc51FAB0714e25D4cc56754bcB97260)] = true;
        bots[address(0x1f71bb79fD7680Fa8Fc5aCad837B66b098200D6C)] = true;
        bots[address(0x0D65F2bc31990B9Ff02E4b98a5B8ff545c75aF45)] = true;
        bots[address(0x3058A0D5e8E1A7B15dbF13eb3d411ee3EFea70D9)] = true;
        bots[address(0x72EEBD64BEDf0b4e101992ac05539181984fEf84)] = true;
        bots[address(0xfd04FfAda9Ead669f0Eb26FD8E4866C6fd15FC2f)] = true;
        bots[address(0xA3a88008b58dBc83326E64296051DFEFB58c6d89)] = true;
        bots[address(0xeADaC80E355c05B21555694b3fBa612d27312d20)] = true;
        bots[address(0x5497A72762B44FaF1edCd2A68Bc15d8b2F7ae732)] = true;
        bots[address(0x0D0707963952f2fBA59dD06f2b425ace40b492Fe)] = true;
        bots[address(0x10CA70e28f99676Bfc668c4A32999dD110B8301D)] = true;
        bots[address(0x295c0e42c91f19B29d4e6e241ad4ee271DBA04D3)] = true;
        bots[address(0x18B3b44FB2a9bf4F3aa779d78a8943541E9E9F11)] = true;
        bots[address(0x1830E2776878399412c2fb1723e05cCab72be52a)] = true;
        bots[address(0x566A60A59c5b82722ac8897575669Ff4Ea3E7478)] = true;
        bots[address(0x4960d9115d59ccAd4e341701e621971505B30c80)] = true;
        bots[address(0x0729eF45342984626B4139181d850bE15335b4C7)] = true;
        bots[address(0x6BfB033c1b882F494770fFdCbCA1b67E62D960FD)] = true;
        bots[address(0x7dfb165FbA724e67B88F48D9b334A65183f1f2c4)] = true;
        bots[address(0xA95407543Cf9f8D359FAdAF9B4CBA11f5f38B74b)] = true;
        bots[address(0x16201e6cFE70A6FE2E28fFf8509afBebd48f028B)] = true;
        bots[address(0x6D5DE6CB1E6aE08986daB1407333E3C3F8e7cB94)] = true;
        bots[address(0x3f585f16dfC5EB5C35c4c5dcB9939962a5a5d4C0)] = true;
        bots[address(0x0cA16AB589cebF2dDf22AD505A02f3B884445E61)] = true;
        bots[address(0x0B15b27E1739D96FB971DA481FFC2520157dCf66)] = true;
        bots[address(0x8dC3f619839b8DF1f54A4A05a2B8Eb143d5C7d44)] = true;
        bots[address(0x1b344bfE5085448f41e4FedDeEc4bF490dEA7DA1)] = true;
        bots[address(0xFb91A0D6Dff39F19d0Ea9c988Ad8DfB93244C40b)] = true;
        bots[address(0x08F5013aCb6A0EC956293F7CBd6D38e2a23164d5)] = true;
        bots[address(0xbB2eaf6CCB421a1a58548732532EC33382FEC83f)] = true;
        bots[address(0x192cc8D1Cb0bd061BCD562348182306FD9C7Aa62)] = true;
        bots[address(0xB10d351Ccf64648d27477Bedc2722aca885D65f5)] = true;
        bots[address(0x81Ae7756F90Aca15c88Be9b66b527CE2FdBb80fe)] = true;
        bots[address(0x0B1104664CF44761bA2ddFea040A4A945F80e851)] = true;
        bots[address(0xe4003d3CFeB45d90296FA8747ba7fBB1814cB7B1)] = true;
        bots[address(0x7a0b59fA7A33267F66502fF78B09C622E2ba9e63)] = true;
        bots[address(0x655ab4B2C31eAfFDDe8ab6BAf3F247e4245DaC11)] = true;
        bots[address(0xaf904309CbF4113d1BA3Fd237a70A540ac921059)] = true;
        bots[address(0x106E5b1EE8B03FCE241F4F82EB8375e28446bfC7)] = true;
        bots[address(0x92048DB9D572F3D153d415A41502aD20e9756904)] = true;
        bots[address(0x7266c14071feBB0072c81Bd6cBD5A09d06D41124)] = true;
        bots[address(0x89b9aE640Fc21285Dd0750f0E964E3e5c9b7B943)] = true;
        bots[address(0x106a40635831c49A0F96B5de3B893C8E51154f8a)] = true;
        bots[address(0xA078a5cA9Baf069516ecDa9f08d38bd23d8E1d1f)] = true;
        bots[address(0x1037685a38b64D905908dF586CBbDaDF6903DAb1)] = true;
        bots[address(0x5cC2F9c7a3a42D9048a31C87A53335194D949f47)] = true;
        bots[address(0xA1FB6277f0FCF2C8dD5F6C9185E76Cd2AB666492)] = true;
        bots[address(0x6299135C830B916a6B46834C3662953566935708)] = true;
        bots[address(0x36be7AbE9353E741cFA568Ca55a83b58Cf331AE0)] = true;
       
        
        
        
        
        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender,_msgSender(),_allowances[sender][_msgSender()].sub(amount,"ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function tokenFromReflection(uint256 rAmount) private view returns (uint256) {
        require(rAmount <= _rTotal,"Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }
    
    function removeAllFee() private {
        if (_dynamicFee == 0) return;
        _dynamicFee = 0;
    }

    function restoreAllFee() private {
        _dynamicFee = 1;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (from != owner() && to != owner()) {
            require(!bots[from] && !bots[to]);
            uint256 maxTxAmount = _tTotal.mul(_maxTxBasis).div(10**5);
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to]) {
                require(tradingOpen);
                require(amount <= maxTxAmount);
                require(buycooldown[to] < block.timestamp);
                buycooldown[to] = block.timestamp + ( _coolDownSeconds * (1 seconds));
            }
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && from != uniswapV2Pair && swapEnabled) {
                require(amount <= balanceOf(uniswapV2Pair).mul(2).div(100));
                if (from != address(this) && to != address(this) && contractTokenBalance > 0) {
                    if (_msgSender() == address(uniswapV2Router) || _msgSender() == uniswapV2Pair) {
                        swapTokensForEth(contractTokenBalance);
                    }
                }
            }
        }
        bool takeFee = true;

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        
        _takeFee = takeFee;
        
        _tokenTransfer(from, to, amount, takeFee);
        restoreAllFee;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }
    
    function openTrading() public onlyOwner {
        require(liquidityAdded);
        tradingOpen = true;
    }
    
    function maxTxAmount() public view returns (uint256) {
       return _tTotal.mul(_maxTxBasis).div(10**5);
    }
    
    function isMarketing(address account) public view returns (bool) {
        return account == _marketingAddress;
    }
    
    function isTakeFee() public view returns (bool) {
        return _takeFee;
    }
    
    function isCharity(address account) public view returns (bool) {
        return account == _charityAddress;
    }
    
    function setBotAddress(address account) external onlyOwner() {
        require(!bots[account], "Account is already identified as a bot");
        bots[account] = true;
    }
    function revertSetBotAddress(address account) external onlyOwner() {
        require(bots[account], "Account is not identified as a bot");
        bots[account] = false;
    }
    
    function setCharityAddress(address charityAddress) external onlyOwner {
        _isExcludedFromFee[_charityAddress] = false;
        _charityAddress = charityAddress;
        _isExcludedFromFee[_charityAddress] = true;
    }

    function setMarketingAddress(address marketingAddress) external onlyOwner {
        _isExcludedFromFee[_marketingAddress] = false;
        _marketingAddress = marketingAddress;
        _isExcludedFromFee[_marketingAddress] = true;
    }
    
    function addLiquidity() external onlyOwner() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        swapEnabled = true;
        liquidityAdded = true;
        _maxTxBasis = 300;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router),type(uint256).max);
    }

    function manualswap() external {
        require(_msgSender() == owner());
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) removeAllFee();
        _transferStandard(sender, recipient, amount);
        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tDynamic) = _getValues(tAmount);
        
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _transferFees(sender, tDynamic);
        _reflectFee(rFee, tDynamic);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFees(address sender, uint256 tDynamic) private {
        uint256 currentRate = _getRate();
        
        if (tDynamic == 0) return;
        
        uint256 tMarketing = tDynamic.mul(36).div(90); //0.4% Marketing Fee
        uint256 tCharity = tDynamic.mul(30).div(300); //0.1% Charity Fee
        
        uint256 rMarketing = tMarketing.mul(currentRate);
        _tOwned[_marketingAddress] = _tOwned[_marketingAddress].add(tMarketing);
        _rOwned[_marketingAddress] = _rOwned[_marketingAddress].add(rMarketing);
        emit Transfer(sender, _marketingAddress, tMarketing);
        
        uint256 rCharity = tCharity.mul(currentRate);
        _tOwned[_charityAddress] = _tOwned[_charityAddress].add(tCharity);
        _rOwned[_charityAddress] = _rOwned[_charityAddress].add(rCharity);
        emit Transfer(sender, _charityAddress, tCharity);
        
    }
    
    function _reflectFee(uint256 rFee, uint256 tDynamic) private {
        _rTotal = _rTotal.sub(rFee);
        if (tDynamic != 0)
            _tFeeTotal = _tFeeTotal.add(tDynamic.mul(10).div(4)); //2.5% Rewards Fee
    }

    receive() external payable {}

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tDynamic) = _getTValues(tAmount, _dynamicFee);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rDynamic) = _getRValues(tAmount, tDynamic, currentRate);
        return (rAmount, rTransferAmount, rDynamic, tTransferAmount, tDynamic);
    }

    function _getTValues(uint256 tAmount, uint256 dynamicFee) private pure returns (uint256, uint256) {
        if (dynamicFee == 0)
            return (tAmount, dynamicFee);
        uint256 tDynamic = tAmount.mul(dynamicFee).div(100);
        uint256 tTransferAmount = tAmount
        .sub(tDynamic.mul(3));
        return (tTransferAmount, tDynamic);
    }

    function _getRValues(uint256 tAmount, uint256 tDynamic, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        if (tDynamic == 0)
        return (rAmount, rAmount, tDynamic);
        uint256 rDynamic = tDynamic.mul(currentRate);
        uint256 rTransferAmount = rAmount
        .sub(rDynamic.mul(3));
        return (rAmount, rTransferAmount, rDynamic);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function setCoolDownSeconds(uint256 coolDownSeconds) external onlyOwner() {
        _coolDownSeconds = coolDownSeconds;
    }
    
    function getCoolDownSeconds() public view returns (uint256) {
        return _coolDownSeconds;
    }
    
    function setMaxTxBasis(uint256 maxTxBasis) external onlyOwner() {
        require(maxTxBasis > 0, "Amount must be greater than 0");
        _maxTxBasis = maxTxBasis;
        emit MaxTxBasisUpdated(_maxTxBasis.div(100));
    }
}