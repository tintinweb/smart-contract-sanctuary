// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// import &#39;ds-auth/auth.sol&#39;;
pragma solidity ^0.4.23;

contract DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) public view returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        public
        auth
    {
        authority = authority_;
        emit LogSetAuthority(authority);
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig));
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, this, sig);
        }
    }
}

/// math.sol -- mixin for inline numerical wizardry

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.4.13;

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It&#39;s O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}


// import &#39;./IkuraStorage.sol&#39;;

/**
 *
 * ロジックの更新に影響されない永続化データを保持するクラス
 *
 */
contract IkuraStorage is DSMath, DSAuth {
  // オーナー（中央銀行）のアドレス
  address[] ownerAddresses;

  // 各アドレスのdJPYの口座残高
  mapping(address => uint) coinBalances;

  // 各アドレスのSHINJI tokenの口座残高
  mapping(address => uint) tokenBalances;

  // 各アドレスが指定したアドレスに対して許可する最大送金額
  mapping(address => mapping (address => uint)) coinAllowances;

  // dJPYの発行高
  uint _totalSupply = 0;

  // 手数料率
  // 0.01pips = 1
  // 例). 手数料を 0.05% とする場合は 500
  uint _transferFeeRate = 500;

  // 最低手数料額
  // 1 = 1dJPY
  // amount * 手数料率で算出した金額がここで設定した最低手数料を下回る場合は、最低手数料額を手数料とする
  uint8 _transferMinimumFee = 5;

  address tokenAddress;
  address multiSigAddress;
  address authorityAddress;

  // @NOTE リリース時にcontractのdeploy -> watch contract -> setOwnerの流れを
  //省略したい場合は、ここで直接controllerのアドレスを指定するとショートカットできます
  // 勿論テストは通らなくなるので、テストが通ったら試してね
  constructor() public DSAuth() {
    /*address controllerAddress = 0x34c5605A4Ef1C98575DB6542179E55eE1f77A188;
    owner = controllerAddress;
    LogSetOwner(controllerAddress);*/
  }

  function changeToken(address tokenAddress_) public auth {
    tokenAddress = tokenAddress_;
  }

  function changeAssociation(address multiSigAddress_) public auth {
    multiSigAddress = multiSigAddress_;
  }

  function changeAuthority(address authorityAddress_) public auth {
    authorityAddress = authorityAddress_;
  }

  // --------------------------------------------------
  // functions for _totalSupply
  // --------------------------------------------------

  /**
   * 総発行額を返す
   *
   * @return 総発行額
   */
  function totalSupply() public view auth returns (uint) {
    return _totalSupply;
  }

  /**
   * 総発行数を増やす（mintと並行して呼ばれることを想定）
   *
   * @param amount 鋳造数
   */
  function addTotalSupply(uint amount) public auth {
    _totalSupply = add(_totalSupply, amount);
  }

  /**
   * 総発行数を減らす（burnと並行して呼ばれることを想定）
   *
   * @param amount 鋳造数
   */
  function subTotalSupply(uint amount) public auth {
    _totalSupply = sub(_totalSupply, amount);
  }

  // --------------------------------------------------
  // functions for _transferFeeRate
  // --------------------------------------------------

  /**
   * 手数料率を返す
   *
   * @return 現在の手数料率
   */
  function transferFeeRate() public view auth returns (uint) {
    return _transferFeeRate;
  }

  /**
   * 手数料率を変更する
   *
   * @param newTransferFeeRate 新しい手数料率
   *
   * @return 更新に成功したらtrue、失敗したらfalse（今のところ失敗するケースはない）
   */
  function setTransferFeeRate(uint newTransferFeeRate) public auth returns (bool) {
    _transferFeeRate = newTransferFeeRate;

    return true;
  }

  // --------------------------------------------------
  // functions for _transferMinimumFee
  // --------------------------------------------------

  /**
   * 最低手数料返す
   *
   * @return 現在の最低手数料
   */
  function transferMinimumFee() public view auth returns (uint8) {
    return _transferMinimumFee;
  }

  /**
   * 最低手数料を変更する
   *
   * @param newTransferMinimumFee 新しい最低手数料
   *
   * @return 更新に成功したらtrue、失敗したらfalse（今のところ失敗するケースはない）
   */
  function setTransferMinimumFee(uint8 newTransferMinimumFee) public auth {
    _transferMinimumFee = newTransferMinimumFee;
  }

  // --------------------------------------------------
  // functions for ownerAddresses
  // --------------------------------------------------

  /**
   * 指定したユーザーアドレスをオーナーの一覧に追加する
   *
   * トークンの移動時に内部的にオーナーのアドレスを管理するための関数。
   * トークンの所有者 = オーナーという扱いになったので、この配列に含まれるアドレスの一覧は
   * 手数料からの収益の分配をする時に利用するだけで、オーナーかどうかの判定には利用しない
   *
   * @param addr ユーザーのアドレス
   *
   * @return 処理に成功したらtrue、失敗したらfalse
   */
  function addOwnerAddress(address addr) internal returns (bool) {
    ownerAddresses.push(addr);

    return true;
  }

  /**
   * 指定したユーザーアドレスをオーナーの一覧から削除する
   *
   * トークンの移動時に内部的にオーナーのアドレスを管理するための関数。
   *
   * @param addr オーナーに属するユーザーのアドレス
   *
   * @return 処理に成功したらtrue、失敗したらfalse
   */
  function removeOwnerAddress(address addr) internal returns (bool) {
    uint i = 0;

    while (ownerAddresses[i] != addr) { i++; }

    while (i < ownerAddresses.length - 1) {
      ownerAddresses[i] = ownerAddresses[i + 1];
      i++;
    }

    ownerAddresses.length--;

    return true;
  }

  /**
   * 最初のオーナー（contractをdeployしたユーザー）のアドレスを返す
   *
   * @return 最初のオーナーのアドレス
   */
  function primaryOwner() public view auth returns (address) {
    return ownerAddresses[0];
  }

  /**
   * 指定したアドレスがオーナーアドレスに登録されているか返す
   *
   * @param addr ユーザーのアドレス
   *
   * @return オーナーに含まれている場合はtrue、含まれていない場合はfalse
   */
  function isOwnerAddress(address addr) public view auth returns (bool) {
    for (uint i = 0; i < ownerAddresses.length; i++) {
      if (ownerAddresses[i] == addr) return true;
    }

    return false;
  }

  /**
   * オーナー数を返す
   *
   * @return オーナー数
   */
  function numOwnerAddress() public view auth returns (uint) {
    return ownerAddresses.length;
  }

  // --------------------------------------------------
  // functions for coinBalances
  // --------------------------------------------------

  /**
   * 指定したユーザーのdJPY残高を返す
   *
   * @param addr ユーザーのアドレス
   *
   * @return dJPY残高
   */
  function coinBalance(address addr) public view auth returns (uint) {
    return coinBalances[addr];
  }

  /**
   * 指定したユーザーのdJPYの残高を増やす
   *
   * @param addr ユーザーのアドレス
   * @param amount 差分
   *
   * @return 処理に成功したらtrue、失敗したらfalse
   */
  function addCoinBalance(address addr, uint amount) public auth returns (bool) {
    coinBalances[addr] = add(coinBalances[addr], amount);

    return true;
  }

  /**
   * 指定したユーザーのdJPYの残高を減らす
   *
   * @param addr ユーザーのアドレス
   * @param amount 差分
   *
   * @return 処理に成功したらtrue、失敗したらfalse
   */
  function subCoinBalance(address addr, uint amount) public auth returns (bool) {
    coinBalances[addr] = sub(coinBalances[addr], amount);

    return true;
  }

  // --------------------------------------------------
  // functions for tokenBalances
  // --------------------------------------------------

  /**
   * 指定したユーザーのSHINJIトークンの残高を返す
   *
   * @param addr ユーザーのアドレス
   *
   * @return SHINJIトークン残高
   */
  function tokenBalance(address addr) public view auth returns (uint) {
    return tokenBalances[addr];
  }

  /**
   * 指定したユーザーのSHINJIトークンの残高を増やす
   *
   * @param addr ユーザーのアドレス
   * @param amount 差分
   *
   * @return 処理に成功したらtrue、失敗したらfalse
   */
  function addTokenBalance(address addr, uint amount) public auth returns (bool) {
    tokenBalances[addr] = add(tokenBalances[addr], amount);

    if (tokenBalances[addr] > 0 && !isOwnerAddress(addr)) {
      addOwnerAddress(addr);
    }

    return true;
  }

  /**
   * 指定したユーザーのSHINJIトークンの残高を減らす
   *
   * @param addr ユーザーのアドレス
   * @param amount 差分
   *
   * @return 処理に成功したらtrue、失敗したらfalse
   */
  function subTokenBalance(address addr, uint amount) public auth returns (bool) {
    tokenBalances[addr] = sub(tokenBalances[addr], amount);

    if (tokenBalances[addr] <= 0) {
      removeOwnerAddress(addr);
    }

    return true;
  }

  // --------------------------------------------------
  // functions for coinAllowances
  // --------------------------------------------------

  /**
   * 送金許可金額を返す
   *
   * @param owner_ 送金者
   * @param spender 送金代行者
   *
   * @return 送金許可金額
   */
  function coinAllowance(address owner_, address spender) public view auth returns (uint) {
    return coinAllowances[owner_][spender];
  }

  /**
   * 送金許可金額を指定した金額だけ増やす
   *
   * @param owner_ 送金者
   * @param spender 送金代行者
   * @param amount 金額
   *
   * @return 更新に成功したらtrue、失敗したらfalse
   */
  function addCoinAllowance(address owner_, address spender, uint amount) public auth returns (bool) {
    coinAllowances[owner_][spender] = add(coinAllowances[owner_][spender], amount);

    return true;
  }

  /**
   * 送金許可金額を指定した金額だけ減らす
   *
   * @param owner_ 送金者
   * @param spender 送金代行者
   * @param amount 金額
   *
   * @return 更新に成功したらtrue、失敗したらfalse
   */
  function subCoinAllowance(address owner_, address spender, uint amount) public auth returns (bool) {
    coinAllowances[owner_][spender] = sub(coinAllowances[owner_][spender], amount);

    return true;
  }

  /**
   * 送金許可金額を指定した値に更新する
   *
   * @param owner_ 送金者
   * @param spender 送金代行者
   * @param amount 送金許可金額
   *
   * @return 指定に成功したらtrue、失敗したらfalse
   */
  function setCoinAllowance(address owner_, address spender, uint amount) public auth returns (bool) {
    coinAllowances[owner_][spender] = amount;

    return true;
  }

  /**
   * 権限チェック用関数のoverride
   *
   * @param src 実行者アドレス
   * @param sig 実行関数の識別子
   *
   * @return 実行が許可されていればtrue、そうでなければfalse
   */
  function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
    sig; // #HACK

    return  src == address(this) ||
            src == owner ||
            src == tokenAddress ||
            src == authorityAddress ||
            src == multiSigAddress;
  }
}

/**
 *
 * アクセス権限を制御するクラス
 *
 */
contract IkuraAuthority is DSAuthority, DSAuth {
  // データの永続化ストレージ
  IkuraStorage tokenStorage;

  // 対称アクションが投票を必要としている場かどうかのマッピング
  // #TODO 後から投票アクションを増減させたいのであれば、これもstorageクラスに持っていったほうがよい？
  mapping(bytes4 => bool) actionsWithToken;

  // 誰からも呼び出すことができないアクション
  mapping(bytes4 => bool) actionsForbidden;

  // @NOTE リリース時にcontractのdeploy -> watch contract -> setOwnerの流れを
  //省略したい場合は、ここで直接controllerのアドレスを指定するとショートカットできます
  // 勿論テストは通らなくなるので、テストが通ったら試してね
  constructor() public DSAuth() {
    /*address controllerAddress = 0x34c5605A4Ef1C98575DB6542179E55eE1f77A188;
    owner = controllerAddress;
    LogSetOwner(controllerAddress);*/
  }

  /**
   * ストレージを更新する
   *
   * @param storage_ 新しいストレージのアドレス
   */
  function changeStorage(address storage_) public auth {
    tokenStorage = IkuraStorage(storage_);

    // トークンの保有率による承認プロセスが必要なアクションを追加
    actionsWithToken[stringToSig(&#39;mint(uint256)&#39;)] = true;
    actionsWithToken[stringToSig(&#39;burn(uint256)&#39;)] = true;
    actionsWithToken[stringToSig(&#39;confirmProposal(string, uint256)&#39;)] = true;
    actionsWithToken[stringToSig(&#39;numberOfProposals(string)&#39;)] = true;

    // 誰からも呼び出すことができないアクションを追加
    actionsForbidden[stringToSig(&#39;forbiddenAction()&#39;)] = true;
  }

  /**
   * 権限チェックのoverride
   * オーナーのみ許可する
   *
   * @param src 実行者アドレス
   * @param dst 実行contract
   * @param sig 実行関数の識別子
   *
   * @return 呼び出し権限を持つ場合はtrue、そうでない場合はfalse
   */
  function canCall(address src, address dst, bytes4 sig) public constant returns (bool) {
    // 投票が必要なアクションの場合には別ロジックでチェックを行う
    if (actionsWithToken[sig]) return canCallWithAssociation(src, dst);

    // 誰からも呼ぶことができないアクション
    if (actionsForbidden[sig]) return canCallWithNoOne();

    // デフォルトの権限チェック
    return canCallDefault(src);
  }

  /**
   * デフォルトではオーナーメンバー　かどうかをチェックする
   *
   * @return オーナーメンバーである場合はtrue、そうでない場合はfalse
   */
  function canCallDefault(address src) internal view returns (bool) {
    return tokenStorage.isOwnerAddress(src);
  }

  /**
   * トークン保有者による投票が必要なアクション
   *
   * @param src 実行者アドレス
   * @param dst 実行contract
   *
   * @return アクションを許可する場合はtrue、却下された場合はfalse
   */
  function canCallWithAssociation(address src, address dst) internal view returns (bool) {
    // warning抑制
    dst;

    return tokenStorage.isOwnerAddress(src) &&
           (tokenStorage.numOwnerAddress() == 1 || tokenStorage.tokenBalance(src) > 0);
  }

  /**
   * 誰からも呼ぶことのできないアクション
   * テスト用の関数です
   *
   * @return 常にfalseを返す
   */
  function canCallWithNoOne() internal pure returns (bool) {
    return false;
  }

  /**
   * 関数定義からfunction identifierへ変換する
   *
   * #see http://solidity.readthedocs.io/en/develop/units-and-global-variables.html#block-and-transaction-properties
   *
   * @param str 関数定義
   *
   * @return ハッシュ化されたキーの4バイト
   */
  function stringToSig(string str) internal pure returns (bytes4) {
    return bytes4(keccak256(str));
  }
}