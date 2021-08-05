/**
 *Submitted for verification at BscScan.com on 2021-08-05
*/

pragma solidity ^0.5.0;
library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}
contract Context {
    constructor () internal { }
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}
contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
interface IBEP20 { 
	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom( address sender, address recipient, uint256 amount ) external returns (bool);
	function mint(address account, uint256 amount) external returns (bool);
	function burn(address account, uint256 amount) external returns (bool);
	function addOperator(address minter) external returns (bool);
	function removeOperator(address minter) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval( address indexed owner, address indexed spender, uint256 value );
}
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;
    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(IBEP20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function safeIncreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function safeDecreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        // uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeBEP20: decreased allowance below zero");
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(IBEP20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeBEP20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) { 
            require(abi.decode(returndata, (bool)), "SafeBEP20: ERC20 operation did not succeed");
        }
    }
}
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}
interface NftLegendCard {
    function mint(address _to, uint256 _tokenId, string calldata _tokenURI ) external returns (bool);
}
 
interface BuyPackage{
    function numberC(uint256 _numberc) external view returns (uint256); // numberC[number] = currentNumberCardC;
    function numberR(uint256 _numberr) external view returns (uint256); // numberR[number] = currentNumberCardD;
    // mapping(uint256 => uint256) public numberC; // numberC[number] = currentNumberCardC;
    // mapping(uint256 => uint256) public numberR; // numberR[number] = currentNumberCardD;
}
contract BuyPackageLucky is Ownable {
    using SafeMath for uint;
    using SafeBEP20 for IBEP20;
    IBEP20 public tokennfl;
    IBEP20 public lucky;
	NftLegendCard public tokenerc721;
    BuyPackage public buyPackage;
    uint256 amountBuyPackage = 25000000;
    uint256 amountLuckyBuyPackageSR = 200000000000000000000; // 200 LUCKY
    uint256 amountLuckyBuyPackageSSR = 400000000000000000000; // 400 LUCKY 
	uint256 public package = 10;
    address payable burnAddress = 0xF3177c2822a33457BDf7e2944c3F986D51a7bf81;
    uint256 public maxBuy = 534;
    uint256 public numberOfPurchases = 0;
    uint256 public maxC = 1000;
    uint256 public maxR = 500;
    uint256 public maxSR = 25;
    uint256 public maxSSR = 10;
    uint256 public feeBnb = 20000000000000000;

    mapping(uint256 => uint256) public numberC; // numberC[number] = currentNumberCardC;
    mapping(uint256 => uint256) public numberR; // numberR[number] = currentNumberCardR;
    mapping(uint256 => uint256) public numberSR; // numberR[number] = currentNumberCardSR;
    mapping(uint256 => uint256) public numberSSR; // numberR[number] = currentNumberCardSSR;
    //Random 
    string[105] stringuri = [string('1'), '2', '3', '4', '5', '6', '7','8', '9','10', '11', '12', '13', '14', '15', '16','17', '18','19', '20', '21', '22', '23', '24', '25','26', '27','28', '29', '30', '31', '32', '33', '34','35', '36','37', '38', '39', '40', '41', '42', '43','44', '45','46', '47', '48', '49', '50', '51', '52','53', '54','55', '56', '57', '58', '59', '60', '61','62', '63','64', '65', '66', '67','78', '69','70', '71', '72', '73', '74', '75', '76','77', '78','79', '80', '81','82', '83','84','85','86', '87', '88', '89','90', '91','92', '93', '94', '95', '96', '97', '98','99', '100','101', '102', '103','104', '105'];
    // string[10] stringuri = [string('1'), '2', '3', '4', '5', '6', '7','8', '9','10'];
    event historyBuyCard(
		address buyer,
		uint256 timeBuy,
		uint256 blockBuy,
		uint256 tokenId,
		string tokenUri
	);

    constructor( address _tokenerc721 ,address _tokennfl, address _tokenBuyPackage, address _tokenLucky) public {
		tokenerc721 = NftLegendCard(_tokenerc721); // Token NFTLegendCard
        tokennfl = IBEP20(_tokennfl); // Token NFL
        buyPackage = BuyPackage(_tokenBuyPackage); // Contract BuyPackage
        lucky = IBEP20(_tokenLucky); // Lucky
	}

    function changeFee(uint256 _fee) public onlyOwner {
        require(_fee > 0, 'need fee > 0');
        feeBnb = _fee;
    }

    function changeMaxC(uint256 _maxc) public onlyOwner {
		require(_maxc > 0, 'need maxc > 0');
		maxC = _maxc;
	}

    function changeMaxR(uint256 _maxr) public onlyOwner {
		require(_maxr > 0, 'need maxr > 0');
		maxR = _maxr;
	}

    function changeMaxSR(uint256 _maxsr) public onlyOwner {
		require(_maxsr > 0, 'need maxsr > 0');
		maxSR = _maxsr;
	}

    function changeMaxSSR(uint256 _maxssr) public onlyOwner {
		require(_maxssr > 0, 'need maxssr > 0');
		maxSSR = _maxssr;
	}
 
	function changeAmountBuyPackage(uint256 _amount) public onlyOwner {
		require(_amount > 0, 'need amount > 0');
		amountBuyPackage = _amount;
	}

    function changeAmountLuckyBuyPackageSR(uint256 _amount) public onlyOwner {
		require(_amount > 0, 'need amount > 0');
		amountLuckyBuyPackageSR = _amount;
	}

    function changeAmountLuckyBuyPackageSSR(uint256 _amount) public onlyOwner {
		require(_amount > 0, 'need amount > 0');
		amountLuckyBuyPackageSSR = _amount;
	}

    function mappingWithBuyPackage() public onlyOwner {
        for(uint256 i = 1; i < 83; i++){
            if(i < 49){
               numberC[i] = buyPackage.numberC(i);
            }else{
                numberR[i] = buyPackage.numberR(i);
            }
        }
    }
    function buyCard(uint256 _amount , uint256[10] memory uint_tokenId) public payable{
        // C --> [1 - 48] R --> [49 - 82] SR --> [83 - 102] SSR --> [103 104 105] 
        require(_amount == amountBuyPackage, 'Invalid quantity');  
        require(msg.value == feeBnb, 'System fee');
        tokennfl.safeTransferFrom(msg.sender, burnAddress , _amount);
        burnAddress.transfer(feeBnb);
        for(uint256 i =0; i < package; i ++){
            uint256 numberCard;
            if(i == 9) {
                uint256 numberIdR = changeNumberR(uint_tokenId[i]);
                numberCard = numberR[numberIdR] >= maxR ? changeNumberCardR() : numberIdR;
                numberR[numberCard] = numberR[numberCard].add(1);
            }else{
                uint256 numberIdC = changeNumberC(uint_tokenId[i]);
                numberCard = numberC[numberIdC] >= maxC ? changeNumberCardC() : numberIdC;
                numberC[numberCard] = numberC[numberCard].add(1);
            }
            tokenerc721.mint(msg.sender, uint_tokenId[i] , stringuri[numberCard - 1]);
            emit historyBuyCard(
			msg.sender,
			block.timestamp,
			block.number,
            uint_tokenId[i],
			stringuri[i]
		    );
        }
        numberOfPurchases = numberOfPurchases.add(1);	
    }

    function buyCardSR(uint256 _amount , uint256 _amountLucky, uint256[10] memory uint_tokenId) public payable{
        // C --> [1 - 48] R --> [49 - 82] SR --> [83 - 102] SSR --> [103 104 105] 
        require(_amount == amountBuyPackage, 'Invalid quantity');  
        require(_amountLucky == amountLuckyBuyPackageSR, 'Invalid quantity Lucky');
        require(msg.value == feeBnb, 'System fee');
        tokennfl.safeTransferFrom(msg.sender, burnAddress , _amount);
        lucky.safeTransferFrom(msg.sender, burnAddress , _amountLucky);
        burnAddress.transfer(feeBnb);
        for(uint256 i =0; i < package; i ++){
            uint256 numberCard;
            if(i > 8) {
                uint256 numberIdR = changeNumberRAndSR(uint_tokenId[i]);
                if(numberIdR > 82){
                    //Number SR
                    numberCard = numberSR[numberIdR] >= maxSR ? changeNumberCardSR() : numberIdR;
                    numberSR[numberCard] = numberSR[numberCard].add(1);
                }else{
                    //Number R
                    numberCard = numberR[numberIdR] >= maxR ? changeNumberCardR() : numberIdR;
                    numberR[numberCard] = numberR[numberCard].add(1);
                }
            }else{
                uint256 numberIdC = changeNumberC(uint_tokenId[i]);
                numberCard = numberC[numberIdC] >= maxC ? changeNumberCardC() : numberIdC;
                numberC[numberCard] = numberC[numberCard].add(1);
            }
            tokenerc721.mint(msg.sender, uint_tokenId[i] , stringuri[numberCard - 1]);
            emit historyBuyCard(
			msg.sender,
			block.timestamp,
			block.number,
            uint_tokenId[i],
			stringuri[i]
		    );
        }
        numberOfPurchases = numberOfPurchases.add(1);	
    }

    function buyCardSSR(uint256 _amount , uint256 _amountLucky, uint256[10] memory uint_tokenId) public payable{
        // C --> [1 - 48] R --> [49 - 82] SR --> [83 - 102] SSR --> [103 104 105] 
        require(_amount == amountBuyPackage, 'Invalid quantity');  
        require(_amountLucky == amountLuckyBuyPackageSSR, 'Invalid quantity Lucky');
        require(msg.value == feeBnb, 'System fee');
        tokennfl.safeTransferFrom(msg.sender, burnAddress , _amount);
        lucky.safeTransferFrom(msg.sender, burnAddress , _amountLucky);
        burnAddress.transfer(feeBnb);
        for(uint256 i =0; i < package; i ++){
            uint256 numberCard;
            if(i > 8) {
                uint256 numberIdR = changeNumberRAndSRAndSSR(uint_tokenId[i]);
                if(numberIdR <= 82){
                    //Number R
                    numberCard = numberR[numberIdR] >= maxR ? changeNumberCardR() : numberIdR;
                    numberR[numberCard] = numberR[numberCard].add(1);
                } 
                if(numberIdR > 82 && numberIdR < 103){
                    //Number SR
                    numberCard = numberSR[numberIdR] >= maxSR ? changeNumberCardSR() : numberIdR;
                    numberSR[numberCard] = numberSR[numberCard].add(1);
                }
                if(numberIdR >= 103){
                    //Number SSR
                    numberCard = numberSSR[numberIdR] >= maxSSR ? changeNumberCardSSR() : numberIdR;
                    numberSSR[numberCard] = numberSSR[numberCard].add(1);              
                }
            }else{
                uint256 numberIdC = changeNumberC(uint_tokenId[i]);
                numberCard = numberC[numberIdC] >= maxC ? changeNumberCardC() : numberIdC;
                numberC[numberCard] = numberC[numberCard].add(1);
            }
            tokenerc721.mint(msg.sender, uint_tokenId[i] , stringuri[numberCard - 1]);
            emit historyBuyCard(
			msg.sender,
			block.timestamp,
			block.number,
            uint_tokenId[i],
			stringuri[i]
		    );
        }
        numberOfPurchases = numberOfPurchases.add(1);	
    }

 
    function changeNumberCardC() private view returns(uint256) {
        for(uint256 i = 1; i < 49 ; i ++) {
            if(numberC[i] < maxC){
                return i;
            }
        }
    }

    function changeNumberCardR() private view returns(uint256) {
        for(uint256 i = 49; i < 83 ; i ++) {
            if(numberR[i] < maxR){
                return i;
            }
        }
    }

    function changeNumberCardSR() private view returns(uint256) {
        for(uint256 i = 83; i <103 ; i++){
            if(numberSR[i] < maxSR) {
                return i;
            }
        }
    }

    function changeNumberCardSSR() private view returns(uint256) {
        for(uint256 i = 103; i <106 ; i++){
            if(numberSSR[i] < maxSSR) {
                return i;
            }
        }
    }

    function changeNumberRAndSRAndSSR(uint256 _randNonce) public view returns(uint256){
        uint256 random = uint256(keccak256(abi.encodePacked(now, msg.sender, _randNonce))) % 57;
        return random + 49;
    }

    function changeNumberRAndSR(uint256 _randNonce) public view returns(uint256){
        uint256 random = uint256(keccak256(abi.encodePacked(now, msg.sender, _randNonce))) % 54;
        return random + 49;
    }

    function changeNumberR(uint256 _randNonce) public view returns(uint256){
        uint256 random = uint256(keccak256(abi.encodePacked(now, msg.sender, _randNonce))) % 34;
        return random + 49;
    }

    function changeNumberC(uint256 _randNonce) public view returns(uint256){
        uint256 random = uint256(keccak256(abi.encodePacked(now, msg.sender, _randNonce))) % 48;
        return (random + 1);
    }

}