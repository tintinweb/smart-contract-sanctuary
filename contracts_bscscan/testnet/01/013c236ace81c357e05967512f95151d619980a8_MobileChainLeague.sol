/**
 *Submitted for verification at BscScan.com on 2021-09-17
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-03
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-01
*/

/**


                              ███╗░░░███╗░█████╗░██████╗░██╗██╗░░░░░███████╗
                              ████╗░████║██╔══██╗██╔══██╗██║██║░░░░░██╔════╝
                              ██╔████╔██║██║░░██║██████╦╝██║██║░░░░░█████╗░░
                              ██║╚██╔╝██║██║░░██║██╔══██╗██║██║░░░░░██╔══╝░░
                              ██║░╚═╝░██║╚█████╔╝██████╦╝██║███████╗███████╗
                              ╚═╝░░░░░╚═╝░╚════╝░╚═════╝░╚═╝╚══════╝╚══════╝

                                   ░█████╗░██╗░░██╗░█████╗░██╗███╗░░██╗
                                   ██╔══██╗██║░░██║██╔══██╗██║████╗░██║
                                   ██║░░╚═╝███████║███████║██║██╔██╗██║
                                   ██║░░██╗██╔══██║██╔══██║██║██║╚████║
                                   ╚█████╔╝██║░░██║██║░░██║██║██║░╚███║
                                   ░╚════╝░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝

                            ██╗░░░░░███████╗░█████╗░░██████╗░██╗░░░██╗███████╗
                            ██║░░░░░██╔════╝██╔══██╗██╔════╝░██║░░░██║██╔════╝
                            ██║░░░░░█████╗░░███████║██║░░██╗░██║░░░██║█████╗░░
                            ██║░░░░░██╔══╝░░██╔══██║██║░░╚██╗██║░░░██║██╔══╝░░
                            ███████╗███████╗██║░░██║╚██████╔╝╚██████╔╝███████╗
                            ╚══════╝╚══════╝╚═╝░░╚═╝░╚═════╝░░╚═════╝░╚══════╝

*/
pragma solidity ^0.6.12;

// SPDX-License-Identifier: MIT 

interface IERC20 {

    function totalSupply() external view returns (uint256);

    /**
     * @dev Mengembalikan jumlah token yang dimiliki oleh `akun`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Memindahkan token `jumlah` dari akun pemanggil ke `penerima`.
     *
     * Mengembalikan nilai boolean yang menunjukkan apakah operasi berhasil.
     *
     * Memancarkan rincian peristiwa {Transfer}.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Mengembalikan sisa jumlah token yang `pembelanja` akan diizinkan
     * untuk dibelanjakan atas nama `pemilik` melalui {transferFrom}. Ini adalah
     * nol secara default.
     *
     * Nilai ini berubah saat {approve} atau {transferFrom} dipanggil.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Menetapkan `jumlah` biaya sebagai alokasi `pembelanja` di atas token pemanggil.
     *
     * Mengembalikan nilai token yang menunjukkan apakah operasi berhasil.
     *
     * PENTING: Berhati-hatilah bahwa mengubah perizinan dengan metode ini membawa risiko
     * bahwa seseorang dapat menggunakan uang saku lama dan baru dengan cara yang tidak menguntungkan
     * pemesanan transaksi yaitu adanya biaya. Salah satu solusi yang mungkin untuk mengurangi resiko ini
     * syaratnya adalah pertama-tama kurangi biaya menjadi 0 dan atur
     * dinilai yang diinginkan setelahnya:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * tanda tangan {menyetujui}.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Memindahkan token `jumlah` dari `pengirim` ke `penerima` menggunakan
     * mekanisme tunjangan. `jumlah` kemudian dipotong dari pemanggil
     * dan di mengizinkan
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Tanda tangan {Transfer}.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev token disebarkan ketika token ini `nilai` dipindahkan dari satu akun (`dari`) ke
     * akun lain (`ke`).
     *
     * Perhatikan bahwa `nilai` mungkin nol.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Dipancarkan saat kelonggaran `pembelanja` untuk `pemilik` diatur oleh
     * panggilan untuk {menyetujui}. `nilai` adalah tunjangan baru.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



/**
 * @dev Membungkus operasi aritmatika Solidity dengan tambahan overflow
 * dan di periksa.
 *
 * Operasi aritmatika dalam Solidity wrap pada overflow. Ini dapat dengan mudah menghasilkan
 * bug, karena pemrogram biasanya berasumsi bahwa overflow menimbulkan
 * error, yang merupakan perilaku standar dalam bahasa pemrograman tingkat tinggi.
 * `SafeMath` memulihkan intuisi ini dengan mengembalikan transaksi saat
 * operasi meluap.
 *
 * Menggunakan perpustakaan ini alih-alih operasi yang tidak dicentang menghilangkan keseluruhan
 * kelas bug, jadi disarankan untuk selalu menggunakannya.
 */
 
library SafeMath {
    /**
     * @dev Mengembalikan penambahan dua bilangan bulat yang tidak ditandatangani, kembali ke
     * meluap.
     *
     * Mitra untuk operator `+` Solidity.
     *
     * Persyaratan:
     *
     * - Penambahan tidak boleh meluap.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Mengembalikan pengurangan dua bilangan bulat yang tidak ditandatangani, kembali ke
     * overflow (bila hasilnya negatif).
     *
     * Mitra untuk operator `-` Solidity.
     *
     * Persyaratan:
     *
     * - Pengurangan tidak bisa meluap.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Mengembalikan pengurangan dua bilangan bulat yang tidak ditandatangani, kembali dengan pesan khusus aktif
     * overflow (bila hasilnya negatif).
     *
     * Mitra untuk operator `-` Solidity.
     *
     * Persyaratan:
     *
     * - Pengurangan tidak bisa meluap.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Mengembalikan perkalian dua bilangan bulat tidak bertanda, kembali ke
     * overflow.
     *
     * Mitra untuk operator `*` Solidity.
     *
     * Persyaratan:
     *
     * - Perkalian tidak bisa meluap.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Optimalisasi gas: ini lebih murah daripada membutuhkan 'a' tidak menjadi nol, tetapi
        // manfaat hilang jika 'b' juga diuji.
        // Slihat di : https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Mengembalikan pembagian bilangan bulat dari dua bilangan bulat yang tidak ditandatangani. Kembali aktif
     * pembagian dengan nol. Hasilnya dibulatkan menuju nol.
     *
     * Mitra untuk operator `/` Solidity. Catatan: fungsi ini menggunakan a
     * `revert` opcode (yang membiarkan sisa gas tidak tersentuh) saat Solidity
     * menggunakan opcode yang tidak valid untuk mengembalikan (menggunakan semua gas yang tersisa).
     *
     * Persyaratan:
     *
     * - Pembagi tidak boleh nol.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Mengembalikan pembagian bilangan bulat dari dua bilangan bulat yang tidak ditandatangani. Kembali dengan pesan khusus aktif
     * pembagian dengan nol. Hasilnya dibulatkan menuju nol.
     *
     * Mitra untuk operator `/` Solidity. Catatan: fungsi ini menggunakan a
     * `revert` opcode (yang membuat sisa gas tidak tersentuh) saat Solidity
     * menggunakan opcode yang tidak valid untuk mengembalikan (menggunakan semua gas yang tersisa).
     *
     * Persyaratan:
     *
     * - Pembagi tidak boleh nol.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // menegaskan (a == b * c + a % b); // Tidak ada kasus di mana ini tidak berlaku

        return c;
    }

    /**
     * @dev Mengembalikan sisa pembagian dua bilangan bulat tak bertanda. (modulo bilangan bulat tidak bertanda),
     * Mengembalikan saat membagi dengan nol.
     *
     * Mitra untuk operator `%` Solidity. Fungsi ini menggunakan `revert`
     * opcode (yang membuat sisa gas tidak tersentuh) sementara Solidity menggunakan
     * opcode tidak valid untuk dikembalikan (menggunakan semua gas yang tersisa).
     *
     * Persyaratan:
     *
     * - Pembagi tidak boleh nol.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Mengembalikan sisa pembagian dua bilangan bulat tak bertanda. (modulo bilangan bulat tidak bertanda),
     * Mengembalikan dengan pesan khusus saat membagi dengan nol.
     *
     * Mitra untuk operator `%` Solidity. Fungsi ini menggunakan `revert`
     * opcode (yang membuat sisa gas tidak tersentuh) sementara Solidity menggunakan
     * opcode tidak valid untuk dikembalikan (menggunakan semua gas yang tersisa).
     *
     * Persyaratan:
     *
     * - Pembagi tidak boleh nol.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // membungkam peringatan mutabilitas status tanpa menghasilkan bytecode - lihat: https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


/**
 * @dev Kumpulan fungsi yang terkait dengan tipe alamat
 */
library Address {
    /**
     * @dev Mengembalikan nilai true jika `akun` adalah kontrak.
     *
     * [PENTING]
     * ====
     * Tidak aman untuk mengasumsikan bahwa alamat yang mengembalikan fungsi ini
     * false adalah akun milik eksternal (EOA) dan bukan kontrak.
     *
     * Antara lain, `isContract` akan mengembalikan false untuk yang berikut
     * jenis alamat:
     *
     *  - akun milik eksternal
     *  - kontrak dalam konstruksi
     *  - alamat tempat kontrak akan dibuat
     *  - alamat tempat kontrak tinggal, tetapi dihancurkan
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 adalah nilai yang dikembalikan untuk akun yang belum dibuat
        // dan 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 dikembalikan
        // untuk akun tanpa kode, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Penggantian `transfer` Solidity: mengirimkan `jumlah` wei ke
     * `penerima`, meneruskan semua gas yang tersedia dan mengembalikan kesalahan.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] meningkatkan biaya gas
     * opcode tertentu, mungkin membuat kontrak melampaui batas gas 2300
     * dikenakan oleh `transfer`, membuat mereka tidak dapat menerima dana melalui
     * `transfer`. {sendValue} menghapus batasan ini.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[baca selengkapnya].
     *
     * PENTING: karena kontrol ditransfer ke `penerima`, perawatan harus
     * diambil untuk tidak membuat kerentanan reentrancy. Pertimbangkan untuk menggunakan
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Melakukan panggilan fungsi Soliditas menggunakan `panggilan` tingkat rendah. A
     * plain`call` adalah pengganti yang tidak aman untuk panggilan fungsi: gunakan ini
     * fungsi sebagai gantinya.
     *
     * Jika `target` kembali dengan alasan pengembalian, itu digelembungkan oleh ini
     * fungsi (seperti panggilan fungsi Solidity biasa).
     *
     * Mengembalikan data mentah yang dikembalikan. Untuk mengonversi ke nilai pengembalian yang diharapkan,
     * gunakan https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Persyaratan:
     *
     * - `target` harus berupa kontrak.
     * - memanggil `target` dengan `data` tidak boleh dikembalikan.
     *
     * _Tersedia sejak v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev sama seperti {xref-Address-functionCall-address-bytes-}[`functionCall`], tapi dengan
     * `errorMessage` sebagai alasan pengembalian mundur saat `target` dikembalikan.
     *
     * _Tersedia sejak v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev sama seperti {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * tetapi juga mentransfer `nilai` wei ke `target`.
     *
     * Persyaratan:
     *
     * - kontrak panggilan harus memiliki saldo ETH minimal `nilai`.
     * - fungsi Soliditas yang dipanggil harus `dibayar`.
     *
     * _Tersedia sejak v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev sama seperti {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], tapi
     * dengan `errorMessage` sebagai alasan pengembalian mundur saat `target` dikembalikan.
     *
     * _Tersedia sejak v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Cari alasan pengembalian dan gelembungkan jika ada
            if (returndata.length > 0) {
                // Cara termudah untuk menggelembungkan alasan pengembalian adalah menggunakan memori melalui perakitan

                // solhint-disable-next-line no-inline-assembly
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

/**
 * @dev Modul kontrak yang menyediakan mekanisme kontrol akses dasar, di mana
 * ada akun (pemilik) yang dapat diberikan akses eksklusif ke
 * fungsi tertentu.
 *
 * Secara default, akun pemilik akan menjadi orang yang menyebarkan kontrak. Ini
 * nanti bisa diubah dengan {transferOwnership}.
 *
 * Modul ini digunakan melalui pewarisan. Ini akan menyediakan pengubah
 * `hanya pemilik`, yang dapat diterapkan ke fungsi Anda untuk membatasi penggunaannya pada
 * pemilik.
 */
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Menginisialisasi kontrak yang menetapkan penyebar sebagai pemilik awal.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Mengembalikan alamat pemilik saat ini.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Lempar jika dipanggil oleh akun selain pemiliknya.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

     /**
     * @dev Meninggalkan kontrak tanpa pemilik. Tidak akan mungkin untuk menelepon
     * `hanya pemilik` berfungsi lagi. Hanya dapat dipanggil oleh pemilik saat ini.
     *
     * NOTE: Melepaskan kepemilikan akan meninggalkan kontrak tanpa pemilik,
     * sehingga menghapus fungsi apa pun yang hanya tersedia bagi pemiliknya.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Tmengalihkan kepemilikan kontrak ke akun baru (`Pemilik baru`).
     * Hanya dapat dipanggil oleh pemilik saat ini.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Mengunci kontrak untuk pemilik selama waktu yang disediakan
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = now + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Membuka kontrak untuk pemilik ketika waktu kunci terlampaui
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(now > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

// pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


// pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}



// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


contract MobileChainLeague is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 50000000000 *10**18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name   = "Mobile Chain League";
    string private _symbol = "MCL";
    uint8 private _decimals = 18;
    
    uint256 public _holder       = 0;
    uint256 private _previousholder = _holder;
    
    uint256 public _liquidity = 0;
    uint256 private _previousLiquidity = _liquidity;

    uint256 public _burn      = 0;
    uint256 private _previousBurnFee = _burn;

    uint256 public _ecosystem   = 0;
    address public ecosystemwallet = 0xe21dA53539B4bC9bE832FBA039B6c71C14E5A334;
    uint256 private _previousecosystem = _ecosystem;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;

    uint256 public _maxTxAmount = 50000000 * 10**18;
    uint256 private numTokensSellToAddToLiquidity = 5000000 * 10**18;
    
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor () public {
        _rOwned[_msgSender()] = _rTotal;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);  // PCS V2
         // Buat pasangan pancakeswap untuk token baru ini
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // atur sisa variabel kontrak
        uniswapV2Router = _uniswapV2Router;
        
        //mengecualikan pemilik dan kontrak ini dari biaya
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        require(account != 0x10ED43C718714eb63d5aA57B78B54704E256024E, 'We can not exclude Pancake router.');
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    

    
     //untuk menerima BNB dari pancakeV2Router saat bertukar
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidity(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }
    
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_holder).div(
            10**2
        );
    }

    function calculateLiquidity(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidity).div(
            10**2
        );
    }
    
    function removeAllFee() private {
        _holder       = 0;
        _liquidity = 0;
        _burn      = 0;
        _ecosystem   = 0;
    }
    
    function restoreAllFee() private {
        _holder       = 2;
        _liquidity = 2;
        _ecosystem   = 8;
        _burn      = 0;

    }
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        // adalah saldo token dari alamat kontrak ini di atas jumlah minimum
        // token yang kita butuhkan untuk memulai swap + kunci likuiditas?
        // juga, jangan terjebak dalam peristiwa likuiditas melingkar.
        // juga, jangan tukar & cairkan jika pengirim adalah pasangan uniswap.
        uint256 contractTokenBalance = balanceOf(address(this));        
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            //menambah likuiditas
            swapAndLiquify(contractTokenBalance);
        }
        
        //jumlah transfer, itu akan mengambil pajak, membakar, biaya likuiditas
        _tokenTransfer(from,to,amount);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // membagi saldo kontrak menjadi dua bagian
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // menangkap saldo BNB kontrak saat ini.
        // ini agar kami dapat menangkap dengan tepat jumlah BNB yang
        // swap membuat, dan tidak membuat peristiwa likuiditas menyertakan BNB apa pun yang
        // telah dikirim secara manual ke kontrak
        uint256 initialBalance = address(this).balance;

        // tukar token untuk BNB
        swapTokensForEth(half); // <- ini merusak BNB -> BENCI swap saat swap+liquidity dipicu

        // berapa banyak BNB yang baru saja kita tukar?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // hasilkan jalur pasangan token pancakeswap -> WBNB
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // lakukan pertukaran
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // terima berapapun jumlah BNB
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // setujui transfer token untuk mencakup semua skenario yang mungkin
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // menambah likuiditas
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slip tidak dapat dihindari
            0, // slip tidak dapat dihindari
            owner(),
            block.timestamp
        );
    }

    //metode ini bertanggung jawab untuk mengambil semua biaya, jika mengambil Biaya benar
    function _tokenTransfer(address sender, address recipient, uint256 amount) private {
        if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]){
            removeAllFee();
        }
        else{
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }
        
        //Hitung jumlah luka bakar dan jumlah Amal Bakar
        uint256 burnAmt = amount.mul(_burn).div(100);
        uint256 BurnCharityAmt = amount.mul(_ecosystem).div(100);

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, (amount.sub(burnAmt).sub(BurnCharityAmt)));
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, (amount.sub(burnAmt).sub(BurnCharityAmt)));
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, (amount.sub(burnAmt).sub(BurnCharityAmt)));
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, (amount.sub(burnAmt).sub(BurnCharityAmt)));
        } else {
            _transferStandard(sender, recipient, (amount.sub(burnAmt).sub(BurnCharityAmt)));
        }
        
        //Temporarily remove fees to transfer to burn address and BurnCharity wallet
        _holder = 0;
        _liquidity = 0;

        //Send transfers to burn and BurnCharity wallet
        _transferStandard(sender, address(0), burnAmt);
        _transferStandard(sender, ecosystemwallet, BurnCharityAmt);

        //Restore tax and liquidity fees
        _holder = _previousholder;
        _liquidity = _previousLiquidity;


        if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient])
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    //Panggil fungsi ini setelah menyelesaikan pra-penjualan
    function enableAllFees() external onlyOwner() {
        _holder       = 2;
        _previousholder = _holder;
        _liquidity = 2;
        _previousLiquidity = _liquidity;
        _ecosystem   = 8;
        _previousecosystem = _ecosystem;
        _burn      = 0;
        _previousBurnFee = _holder;
        inSwapAndLiquify = true;
        emit SwapAndLiquifyEnabledUpdated(true);
    }

    function disableAllFees() external onlyOwner() {
        _holder       = 0;
        _previousholder = _holder;
        _liquidity = 0;
        _previousLiquidity = _liquidity;
        _burn      = 0;
        _previousBurnFee = _holder;
        _ecosystem   = 0;
        _previousecosystem = _ecosystem;
        inSwapAndLiquify = false;
        emit SwapAndLiquifyEnabledUpdated(false);
    }
    
    function setecosystemwallet(address newWallet) external onlyOwner() {
        ecosystemwallet = newWallet;
    }
   
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        require(maxTxPercent > 10, "Cannot set transaction amount less than 10 percent!");
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(
            10**2
        );
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
}