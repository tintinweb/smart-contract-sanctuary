/**
 *Submitted for verification at BscScan.com on 2022-01-27
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-17
*/

pragma solidity ^0.6.0;
        
        // SPDX-License-Identifier: MIT
        
        library SafeMath {
        function mul(uint256 a, uint256 b) internal pure returns (uint256) {
            if (a == 0) {
            return 0;
            }
            uint256 c = a * b;
            assert(c / a == b);
            return c;
        }
        
        function div(uint256 a, uint256 b) internal pure returns (uint256) {
            
            uint256 c = a / b;
            return c;
        }
        
        function sub(uint256 a, uint256 b) internal pure returns (uint256) {
            assert(b <= a);
            return a - b;
        }
        
        function add(uint256 a, uint256 b) internal pure returns (uint256) {
            uint256 c = a + b;
            assert(c >= a);
            return c;
        }
        
        function ceil(uint a, uint m) internal pure returns (uint r) {
            return (a + m - 1) / m * m;
        }
        }
        
        contract Owned {
            address payable public owner;
        
            event OwnershipTransferred(address indexed _from, address indexed _to);
        
            constructor() public {
                owner = msg.sender;
            }
        
            modifier onlyOwner {
                require(msg.sender == owner);
                _;
            }
        
            function transferOwnership(address payable _newOwner) public onlyOwner {
                owner = _newOwner;
                emit OwnershipTransferred(msg.sender, _newOwner);
            }
        }
        
        
        interface IToken {
            function decimals() external view returns (uint256 balance);
            function transfer(address to, uint256 tokens) external returns (bool success);
            function burnTokens(uint256 _amount) external;
            function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
            function balanceOf(address tokenOwner) external view returns (uint256 balance);
        }
        
        
        contract Soldait is Owned {
            using SafeMath for uint256;
            
            bool public isPresaleOpen;
            
            address public tokenAddress = 0xFD7113a715cEe3d961eDD72E277cB122E2F2744b;
            uint256 public tokenDecimals = 18;
            
            address public BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
            
            uint256 public tokenRatePerEth = 2000;
            uint256 public tokenRatePerBUSD = 3;
            uint256 public rateDecimals = 0;
            
            uint256 public minEthLimit = 1e17; // 0.1 BNB
            uint256 public maxEthLimit = 10e18; // 10 BNB

            uint256 public expectedBNB = 1 ether;
            uint256 public expectedBUSD = 500e18;
            
            uint256 public totalSupply;
            
            uint256 public soldTokens=0;
            
            uint256 public totalsold = 0;
            
            uint256 public intervalDays;
            
            uint256 public endTime = 2 days;
            
            bool public isClaimable = false;
            
            bool public isWhitelisted = false;

            uint256 public lockedPeriod = 180 days;
            
            mapping(address => mapping(address => uint256)) public usersInvestments;

            mapping(address => uint256) public userBusdInvestment;
            
            mapping(address => mapping(address => uint256)) public balanceOf;
            
            mapping(address => mapping(address => uint256)) public whitelistedAddresses;
            
            constructor() public {
                owner = msg.sender;
            }
            
            function startPresale(uint256 numberOfdays) external onlyOwner{
                require(IToken(tokenAddress).balanceOf(address(this)) > 0,"No Funds");
                require(!isPresaleOpen, "Presale is open");
                intervalDays = numberOfdays.mul(1 days);
                endTime = block.timestamp.add(intervalDays);
                isPresaleOpen = true;
                isClaimable = false;
                lockedPeriod = 180 days;
            }
            
            function closePresale() external onlyOwner{
                require(isPresaleOpen, "Presale is not open yet or ended.");
                isPresaleOpen = false;
                
            }
            
            function setTokenAddress(address token) external onlyOwner {
                tokenAddress = token;
                tokenDecimals = IToken(tokenAddress).decimals();
            }
            
            function setTokenDecimals(uint256 decimals) external onlyOwner {
            tokenDecimals = decimals;
            }
            
            function setMinEthLimit(uint256 amount) external onlyOwner {
                minEthLimit = amount;    
            }
            
            function setMaxEthLimit(uint256 amount) external onlyOwner {
                maxEthLimit = amount;    
            }
            
            function setTokenRatePerEth(uint256 rate) external onlyOwner {
                tokenRatePerEth = rate;
            }

            function setTokenRatePerBUSD(uint256 rate) external onlyOwner {
                tokenRatePerBUSD = rate;
            }

            function setLockingPeriod(uint256 _days) external onlyOwner {
                lockedPeriod = _days;
            }
            
            function setRateDecimals(uint256 decimals) external onlyOwner {
                rateDecimals = decimals;
            }

            function setexpectedBNB(uint256 _expectedBNB) external onlyOwner {
                expectedBNB = _expectedBNB;
            }

            function setexpectedBUSD(uint256 _expectedBUSD) external onlyOwner {
                expectedBUSD = _expectedBUSD;
            }

            function setBUSD(address _busd) external onlyOwner {
                BUSD = _busd;
            }
            
            function getUserInvestments(address user) public view returns (uint256){
                return usersInvestments[tokenAddress][user];
            }
            
            function getUserClaimbale(address user) public view returns (uint256){
                return balanceOf[tokenAddress][user];
            }
            
            function addWhitelistedAddress(address _address, uint256 _allocation) external onlyOwner {
                whitelistedAddresses[tokenAddress][_address] = _allocation;
            }
            
            function addMultipleWhitelistedAddresses(address[] calldata _addresses, uint256[] calldata _allocation) external onlyOwner {
                isWhitelisted = true;
                for (uint i=0; i<_addresses.length; i++) {
                    whitelistedAddresses[tokenAddress][_addresses[i]] = _allocation[i];
                }
            }
        
            function removeWhitelistedAddress(address _address) external onlyOwner {
                whitelistedAddresses[tokenAddress][_address] = 0;
            }
            
            receive() external payable{
                if(block.timestamp > endTime)
                isPresaleOpen = false;
                
                require(isPresaleOpen, "Presale is not open.");
                require(
                        usersInvestments[tokenAddress][msg.sender].add(msg.value) <= maxEthLimit
                        && usersInvestments[tokenAddress][msg.sender].add(msg.value) >= minEthLimit,
                        "Installment Invalid."
                    );
                if(isWhitelisted){
                    require(whitelistedAddresses[tokenAddress][msg.sender] > 0, "you are not whitelisted");
                    require(whitelistedAddresses[tokenAddress][msg.sender] >= msg.value, "amount too high");
                    require(usersInvestments[tokenAddress][msg.sender].add(msg.value) <= whitelistedAddresses[tokenAddress][msg.sender], "Maximum purchase cap hit");
                    whitelistedAddresses[tokenAddress][msg.sender] = whitelistedAddresses[tokenAddress][msg.sender].sub(msg.value);
                }
                require( (IToken(tokenAddress).balanceOf(address(this))).sub(soldTokens) > 0 ,"No Presale Funds left");
                uint256 tokenAmount = getTokensPerEth(msg.value);
                balanceOf[tokenAddress][msg.sender] = balanceOf[tokenAddress][msg.sender].add(tokenAmount);
                soldTokens = soldTokens.add(tokenAmount);
                usersInvestments[tokenAddress][msg.sender] = usersInvestments[tokenAddress][msg.sender].add(msg.value);
                owner.transfer(msg.value);
            }

            function contributeBUSD(uint256 _amount) public{
                if(block.timestamp > endTime)
                isPresaleOpen = false;
                
                require(isPresaleOpen, "Presale is not open.");
                require(
                        usersInvestments[tokenAddress][msg.sender].add(_amount) <= maxEthLimit
                        && usersInvestments[tokenAddress][msg.sender].add(_amount) >= minEthLimit,
                        "Installment Invalid."
                    );
                if(isWhitelisted){
                    require(whitelistedAddresses[tokenAddress][msg.sender] > 0, "you are not whitelisted");
                    require(whitelistedAddresses[tokenAddress][msg.sender] >= _amount, "amount too high");
                    require(usersInvestments[tokenAddress][msg.sender].add(_amount) <= whitelistedAddresses[tokenAddress][msg.sender], "Maximum purchase cap hit");
                    whitelistedAddresses[tokenAddress][msg.sender] = whitelistedAddresses[tokenAddress][msg.sender].sub(_amount);
                }
                require(IToken(BUSD).transferFrom(msg.sender,owner, _amount),"Insufficient Funds !");
                require( (IToken(tokenAddress).balanceOf(address(this))).sub(soldTokens) > 0 ,"No Presale Funds left");
                uint256 tokenAmount = getTokensPerBUSD(_amount);
                balanceOf[tokenAddress][msg.sender] = balanceOf[tokenAddress][msg.sender].add(tokenAmount);
                soldTokens = soldTokens.add(tokenAmount);
                userBusdInvestment[msg.sender] = userBusdInvestment[msg.sender].add(_amount);
            }
            
            function claimTokens() public{
                require(!isPresaleOpen, "You cannot claim tokens until the presale is closed.");
                require(isClaimable,"Wait until the owner finalise the sale !");
                require(block.timestamp > lockedPeriod , "Locked Period is still live !");
                require(balanceOf[tokenAddress][msg.sender] > 0 , "No Tokens left !");
                require(IToken(tokenAddress).transfer(msg.sender, balanceOf[tokenAddress][msg.sender]), "Insufficient balance of presale contract!");
                balanceOf[tokenAddress][msg.sender] = 0;
            }
            
            function finalizeSale() public onlyOwner{
                isClaimable = !(isClaimable);
                totalsold = totalsold.add(soldTokens);
                soldTokens = 0;
                lockedPeriod = block.timestamp.add(lockedPeriod);
            }
            
            function whitelistedSale() public onlyOwner{
                isWhitelisted = !(isWhitelisted);
            }
            
            function getTokensPerEth(uint256 amount) public view returns(uint256) {
                return amount.mul(tokenRatePerEth).div(
                    10**(uint256(18).sub(tokenDecimals).add(rateDecimals))
                    );
            }

            function getTokensPerBUSD(uint256 amount) public view returns(uint256) {
                return amount.mul(tokenRatePerBUSD).div(
                    10**(uint256(18).sub(tokenDecimals).add(rateDecimals))
                    );
            }

            function getCollectedBUSD() public view returns (uint256) {
                return IToken(BUSD).balanceOf(address(this));
            }

            function getUserInvestmentsBUSD() public view returns (uint256) {
                return userBusdInvestment[msg.sender];
            }
            
            function withdrawBNB() public onlyOwner{
                // require(address(this).balance > 0 , "No Funds Left");
                owner.transfer(address(this).balance);
                IToken(BUSD).transfer(owner,IToken(BUSD).balanceOf(address(this)));
            }
            
            function getUnsoldTokensBalance() public view returns(uint256) {
                return IToken(tokenAddress).balanceOf(address(this));
            }
            
            function burnUnsoldTokens() external onlyOwner {
                require(!isPresaleOpen, "You cannot burn tokens untitl the presale is closed.");
                
                IToken(tokenAddress).burnTokens(IToken(tokenAddress).balanceOf(address(this)));   
            }
            
            function getUnsoldTokens() external onlyOwner {
                require(!isPresaleOpen, "You cannot get tokens until the presale is closed.");
                IToken(tokenAddress).transfer(owner, (IToken(tokenAddress).balanceOf(address(this))).sub(soldTokens) );
            }
        }