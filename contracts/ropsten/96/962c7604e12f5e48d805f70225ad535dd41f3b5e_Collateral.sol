/**
 *Submitted for verification at Etherscan.io on 2021-05-19
*/

pragma solidity ^0.4.19;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// from cryptozombies lesson4. This library prevent overflow problems.
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Collateral {
    
    // 上から順に債権者（＝担保権者）,債務者（＝担保設定者）のアドレスを挿入する。
    // debtBalanceは総債務額から、債権者アドレスに送金されていない額を引いた額を示す。
    // repayedBalanceは、債権者アドレスに送金された額を示す。
    // dueDateは弁済期を示す。
    address public creditor;
    address public debtor;
    uint debtBalance;
    uint repayedBalance;
    uint dueDate;
    
    // libraryの呼び出し
    using SafeMath for uint;
    
    // インターフェイスの定義
    IERC20 erc20CollateralTokenContract;
    IERC20 erc20LoanTokenContract;
    
    // 債務者及び債権者のアドレス並びに貸付トークン及び担保トークンのコントラクトアドレスは固定しておく。
    // 本来、債務者及び債権者のアドレスhは固定すべきではないとも思えるが、契約の性質上固定する。
    constructor(address _erc20CollateralTokenAddress, address _erc20LoanTokenAddress) public {
        creditor = 0xC960804664D3fAdDcD037240BFD55A2e1F197503;
        debtor = 0xC12392Ae41E31Ea352acB2E5Fd88B1eFF0325c1f;
        erc20CollateralTokenContract = IERC20(_erc20CollateralTokenAddress);
        erc20LoanTokenContract = IERC20(_erc20LoanTokenAddress);
    }
    
    // debtBalanceを確認するための関数
    function getDebtBalance() public view returns (uint) {
        return debtBalance;
    }

    // repayedBalanceを確認するための関数
    function getRepayedBalance() public view returns (uint) {
        return repayedBalance;
    }
    
    // dueDateを確認するための関数
    function getDueDate() public view returns (uint) {
        return dueDate;
    }
    
    // 債務の額を設定する関数。債務の額を増やすのであれば、債務者が自由に債務の額を設定できるようになっている。
    // 債務の額を減少する方向で事後的に合意したのであれば、changeDebtBalance関数を実行すればよい。
    function setAndChangeDebtBalance(uint _debtBalance) public {
        require(msg.sender == debtor);
        require(debtBalance <= _debtBalance);
        debtBalance = _debtBalance;
    }
    
    // 債務の額を変更する関数。債務の額を減らすのであれば、債務者が自由に債務の額を設定できるようになっている。
    // 債務の額を減少する方向で事後的に合意したのであれば、setAndChangeDebtBalance関数を実行すればよい。
    function changeDebtBalance(uint _debtBalance) public {
        require(msg.sender == creditor);
        require(debtBalance > _debtBalance);
        debtBalance = _debtBalance;
    }
    
    // 債務者がコントラクトアドレスに供与した返済金を債務者自身が引き出すための関数
    function returnLoanTokenForDebtor(address _to, uint _amount) public {
	    //この関数を呼び出したアカウントに返済金が移される。
	   // 担保設定者のみ実行可能
	   // 債務の履行後にのみ実行可能
	   // decimalsが18でないerc20トークンは使わないように！！
	   // _amount * 10e17をしないと、小数点第１８位から入力が始まってしまう。
	   // 256桁もの発行量を持つerc20トークンは考えにくいので、乗法計算にsafeMathは使っていない。
	    require(msg.sender == debtor);
	    _amount = _amount.mul(10e17);
	    erc20LoanTokenContract.transfer(_to, _amount);
	}
	
	
	// 債権者がコントラクトアドレスに供与した返済金を引き出すための関数
    function returnLoanTokenForCreditor(address _to, uint _amount) public {
	    //この関数を呼び出したアカウントに返済金が移される。
	   // 担保設定者のみ実行可能
	   // 債務の履行後にのみ実行可能
	    require(msg.sender == creditor);
	    debtBalance = debtBalance.sub(_amount);
	    _amount = _amount.mul(10e17);
	    erc20LoanTokenContract.transfer(_to, _amount);
	}
    
    // 指定したERC20のコントラクトアドレスの中にあるtransfer関数を実行することによって、
    // このコードのコントラクトアドレスに入り込んだERC20TOKENを引き出せるようにしている。
    // withdrawToOwner関数実行時に、任意のアドレスを_toに入れることでコントラクトアドレス内のerc20TOKENを_toアドレスに送ることができる。
    // _amountは小数点第18まで検討する必要がありうる点に注意が必要である。
    // 実装にあたっては、decimalが１８であることを確認するようなコードを書き込むと良いかもしれない。
    // 本当は、 require(debtBalance = 0);にすべきなんだけど、端数が紛れるとめんどくさいからとりあえず< 1にしている。
    // 仮に債権者がこのコードのコントラクトアドレス内から返済金を引き出さなくても、
    // このコントラクトアドレス内に送られた返済額が、残債務（debtBalance)を上回るのであれば、担保を引き出せるようにしている。
    // _toには担保トークンの送り先、_erc20thisContractAddressにはこのコードのコントラクトアドレス、_amountには送る担保トークンの数量を代入する。
    // thisは、このコントラクトのコントラクトアドレスを示す。
	function returnCollateralForDebtor(address _to, uint _amount) public {
	    //この関数を呼び出したアカウントに担保が移される。
	    // this.balanceは、コントラクトアドレス内のETHの総量を示す。
	   // 担保設定者のみ実行可能
	   // 債務の履行後にのみ実行可能
	    require(msg.sender == debtor);
	    _amount = _amount.mul(10e17);
	    require(debtBalance <= erc20LoanTokenContract.balanceOf(this) );
	    erc20CollateralTokenContract.transfer(_to, _amount);
	}
    
    
    // 債権者のみが実行可能
    // 弁済期を設定するためのもの
    // 既に設定された弁済期よりも長い弁済期しか設定できないため、設定者が債権者のみでも債務者保護に資する。
    // _setDueDateは秒数で入力すること
    function setDueDate(uint _setDueDate) public {
        require(msg.sender == creditor);
        require(dueDate < now + _setDueDate);
        dueDate = now + _setDueDate;
    }

	
	// 指定したERC20のコントラクトアドレスの中にあるtransfer関数を実行することによって、
    // このコードのコントラクトアドレスに入り込んだERC20TOKENを引き出せるようにしている。
    // withdrawToOwner関数実行時に、任意のアドレスを_toに入れることでコントラクトアドレス内のerc20TOKENを_toアドレスに送ることができる。
    // _amountは小数点第18まで検討する必要がありうる点に注意が必要である。
    // 実装にあたっては、decimalが１８であることを確認するようなコードを書き込むと良いかもしれない。
    // 債権者のみ実行可能
    // 弁済期経過後に担保実行できる。
	function executeCollateralForCreditor(address _to, uint _amount) public {
	    require(msg.sender == creditor);
	    require(now > dueDate);
	    require(debtBalance > erc20LoanTokenContract.balanceOf(this));
	    _amount = _amount.mul(10e17);
	    erc20CollateralTokenContract.transfer(_to, _amount);
	}
	
}