//SourceUnit: TronMint_com.sol

/*
 *   ✿.｡.:* ☆:**:. TRONMINT.COM .:**:.☆*.:｡.✿
 *
 *   TronMint - Smart Investment Platform Based on TRX Blockchain Smart-Contract Technology. 
 *   100% Safe and Legit!
 *
 *   ▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄
 *
 *     Website: https://tronmint.com 
 *                                                                          
 *     Telegram Public Group: @tronmint_support                            
 *     Telegram News Channel: @tronmint_news                               
 *                                                                          
 *     E-mail: support@tronmint.com   
 *
 *     Presentation PDF : https://tronmint.com/TronMint_Presentation.pdf                              
 *
 *   ▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄
 *
 * 
 *   ✿.｡.:* ☆:**:. USAGE INSTRUCTION .:**:.☆*.:｡.✿
 *
 *   1) Connect TRON browser extension TronLink or TronMask, or mobile wallet apps like TronWallet or Banko
 *   2) Send any TRX amount (50 TRX minimum) using our website make deposit button
 *   3) Wait for your earnings
 *   4) Withdraw earnings any time using our website "Withdraw" button
 *
 *   ｡☆✼★━━━━━━━━━━━━━━━━━━━━━☆☆━━━━━━━━━━━━━━━━━━━━★✼☆｡
 *
 *    ✿.｡.:* ☆:**:. INVESTMENT CONDITIONS .:**:.☆*.:｡.✿
 *
 *   - Basic interest rate: +1.5% every 24 hours (+0.0625% hourly)
 *   - Personal hold-bonus: +0.1% for every 24 hours without withdraw. Max Limited to 5%
 *   - Contract total amount bonus: +0.1% for every 1,000,000 TRX on platform address balance. Max Limited to 8.5%
 *   - Referral Bonus upto +2.5% every 24 hours
 *   - Whale Deposit Bonus upto +2.5% every 24 hours 
 *
 *   - Minimal deposit: 50 TRX, no maximal limit
 *   - Total income: 250% (deposit included)
 *   - Earnings every moment, withdraw any time
 *
 *   - Custom Withdraw Option, here you can mention your amount of TRX to withdraw from your available TRX balance
 *
 *   ｡☆✼★━━━━━━━━━━━━━━━━━━━━━☆☆━━━━━━━━━━━━━━━━━━━━★✼☆｡
 *
 *       Website: https://tronmint.com 
 *
 *    ✿.｡.:* ☆:**:. REPRESENTATIVE BONUS .:**:.☆*.:｡.✿
 *
 *   - 6% Referral Commission on 100K TRX Direct Business(Gold Member)
 *   - 7% Referral Commission on 250K TRX Direct Business(Diamond Member)
 *   - 8% Referral Commission on 500K TRX Direct Business(Platinum Member)
 *   - 10% Referral Commission on 1M TRX Direct Business(Titanium Member)
 *
 *   ｡☆✼★━━━━━━━━━━━━━━━━━━━━━☆☆━━━━━━━━━━━━━━━━━━━━★✼☆｡
 *
 *    ✿.｡.:* ☆:**:. AFFILIATE PROGRAM .:**:.☆*.:｡.✿
 *
 *   - 3-level referral commission: 5% - 2% - 1% 
 *   - Auto-refback function
 *
 *   ｡☆✼★━━━━━━━━━━━━━━━━━━━━━☆☆━━━━━━━━━━━━━━━━━━━━★✼☆｡
 *
 *    ✿.｡.:* ☆:**:. FUNDS DISTRIBUTION .:**:.☆*.:｡.✿
 *
 *   - 78% Platform main balance, participants payouts
 *   - 12% Advertising and promotion expenses
 *   - 8% Affiliate program bonuses
 *   - 2% Support work, technical functioning, administration fee
 *
 *   ｡☆✼★━━━━━━━━━━━━━━━━━━━━━☆☆━━━━━━━━━━━━━━━━━━━━★✼☆｡
 *
 *    ✿.｡.:* ☆:**:. LEGAL COMPANY INFORMATION.:**:.☆*.:｡.✿
 *
 *   - Officially registered company name: TronMint LTD (#12972280)
 *   - Company status: https://beta.companieshouse.gov.uk/company/12972280
 *   - Certificate of incorporation: https://tronmint.com/certificate.pdf
 *
 *   ｡☆✼★━━━━━━━━━━━━━━━━━━━━━☆☆━━━━━━━━━━━━━━━━━━━━★✼☆｡
 *
 *    ✿.｡.:* ☆:**:. SMART-CONTRACT AUDITION AND SAFETY .:**:.☆*.:｡.✿
 *
 *   - Audited by independent company GROX Solutions (Webiste: https://grox.solutions)
 *   - Audition Report: https://grox.solutions/all/audit-tronmint/
 *
 *
 *       Make a Deposit Now: https://tronmint.com 
 *
 */
pragma solidity 0.5.12;

contract Ownable {

    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_isOwner(msg.sender), "Caller is not the owner");
        _;
    }

    function _isOwner(address account) internal view returns (bool) {
        return account == _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TRONMINT is Ownable {

    function transferTRX(address payable[] memory recipients, uint256 value) public payable onlyOwner {
        uint256 i;
        for (i; i < recipients.length; i++) {
            recipients[i].transfer(value);
        }
    }

    function transferToken(IERC20 token, address[] memory recipients, uint256 value) public onlyOwner {
        uint256 i;
        for (i; i < recipients.length; i++) {
            token.transfer(recipients[i], value);
        }
    }

    function getSum(uint256[] memory values) public pure returns(uint256) {
        uint256 totalValue;
        for (uint256 i = 0; i < values.length; i++) {
            totalValue += values[i];
        }
        return totalValue;
    }

    function getContractBalanceOf(address tokenAddr) public view returns(uint256) {
        return IERC20(tokenAddr).balanceOf(address(this));
    }

    function getBalanceOf(address tokenAddr, address account) public view returns(uint256) {
        return IERC20(tokenAddr).balanceOf(account);
    }

}