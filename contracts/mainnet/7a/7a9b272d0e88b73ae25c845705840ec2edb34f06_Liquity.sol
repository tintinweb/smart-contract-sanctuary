/**
 *Submitted for verification at Etherscan.io on 2020-11-19
*/

//번역 사이트 : 영어-> 한국어 / 한국어-> 영어 한국어를 배우는 학생들 당신의 고도를 결정하는 것은 당신의 적성 이 아니라 당신의 태도입니다
//저는 한국어를 한국에서 배웠어요
//그는 그녀의 호의를 순수하게 받아들였다
//그 집은 한국에서 지어졌어요
//저는 한국에서 살고 있어요
//그 집은 한국에서 지어졌어요
//저는 한국에서 살고 있어요
//저는 한국에서 살고 있어요
//저는 7년 동안 한국에서 살았어요 
//한국어능력시험
//대한민국



// UNN finance by 한민국





    
pragma solidity ^0.6.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

interface IERC20 {
    //저는 7년 동안 한국에서 살았어요 
    //한국어능력시험
    //대한민국
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
    //그 집은 한국에서 지어졌어요
    //저는 한국에서 살고 있어요
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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


/*


Lorem Ipsum on yksinkertaisesti testa
usteksti, jota tulostus- ja ladontateollisuudet kä

yttävät. Lorem Ipsum on ollut teollisuuden norm
aali testausteksti jo 1500-luvulta asti, jolloin tunte
maton tulostaja otti kaljuunan ja sekoitti sen tehdäkseen 

esimerkkikirjan. Se ei ole selvinnyt vain viittä vuosisataa, mutta myös loikan elektroni
seen kirjoitukseen, jääden suurinpiirtein muuntamattomana. Se tuli kuuluisuuteen 1960-luvulla kun Letra
set-paperiarkit, joissa oli Lorem Ipsum pätkiä, julkaistiin ja vielä myöh
emmin tietokoneen julkistusohjelm
issa, kuten Aldus PageMaker joissa oli versioita Lorem Ipsumista.

*/

pragma solidity ^0.6.2;
//저는 한국어를 한국에서 배웠어요
//그는 그녀의 호의를 순수하게 받아들였다
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    //번역 사이트 : 영어-> 한국어 / 한국어-> 영어 한국어를 배우는 학생들 당신의 고도를 결정하는 것은 당신의 적성 이 아니라 당신의 태도입니다
    //저는 한국어를 한국에서 배웠어요
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {

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

pragma solidity ^0.6.0;

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    //그 집은 한국에서 지어졌어요
    //저는 한국에서 살고 있어요
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
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
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
/*
Integer pharetra massa eget facilisis commodo.
Integer in dolor vitae eros pretium suscipit et scelerisque neque.
Duis condimentum justo ac volutpat consequat.
Curabitur id erat suscipit, pharetra neque ac, luctus urna.
Sed maximus augue et mauris interdum tristique.
Proin et sem viverra, fringilla massa non, egestas sem.
Nulla id mauris tristique, porta eros sit amet, mollis mauris.
Pellentesque eu magna eu nunc molestie interdum nec nec felis.
Sed non ante at lectus accumsan lobortis nec vitae lectus.
Ut fringilla mi ac est rhoncus, molestie convallis massa consectetur.
Duis cursus sem nec metus commodo, quis consequat est congue.
Fusce convallis erat at lectus pharetra venenatis.
Donec porta ligula et massa congue, lobortis scelerisque quam tempor.
Suspendisse dictum arcu et nibh ullamcorper laoreet.
Fusce quis ex pellentesque, varius erat at, interdum elit.
Nunc sed ex vel neque malesuada cursus.
Donec a mi viverra, venenatis sapien ac, cursus sapien.
Suspendisse mattis felis eget ligula gravida fermentum.
Ut faucibus mauris euismod porta lacinia.
Nam rhoncus tortor non leo lobortis, id commodo ex egestas.
Suspendisse ac leo vel orci aliquam congue.
Vivamus ornare sem vitae metus lacinia hendrerit.
Quisque eget odio a ex sodales sagittis.
Vestibulum auctor ligula ac neque auctor, nec varius metus vulputate.
Pellentesque vitae ex id lectus semper cursus.
Vestibulum eu tellus fringilla, venenatis lacus vel, rutrum elit.
Nam ut velit non magna euismod porttitor non ut odio.
Aenean commodo leo sit amet lobortis pharetra.
Proin eu felis at dui rutrum feugiat.
Nullam cursus metus eu eros volutpat, sed placerat quam condimentum.
Sed mollis leo et arcu tempor, quis lacinia erat rhoncus.
Etiam aliquam augue sed ipsum pretium, ac efficitur lacus varius.
Morbi ac felis fringilla ligula sagittis vehicula ac eu erat.
Nullam aliquam justo scelerisque tortor egestas molestie.
Curabitur fringilla risus vel urna ullamcorper, id placerat nibh fermentum.
Mauris sed dui a dolor dictum bibendum.
Suspendisse lacinia mi eu ligula eleifend varius.
Maecenas blandit ipsum non nulla rhoncus, sed dapibus augue pellentesque.
Vestibulum at lectus pharetra enim mattis ultricies sit amet eget est.
Nulla euismod eros sed cursus vestibulum.
Mauris tincidunt dui quis libero dignissim, nec blandit odio vulputate.
Pellentesque in elit tristique, maximus mauris non, gravida nibh.
Maecenas condimentum dolor et eros tempor, vel consequat ante convallis.
Etiam ultricies lorem vel molestie semper.
Curabitur venenatis diam sit amet porta blandit.
Maecenas eget urna at urna ullamcorper consectetur.
Praesent luctus velit eget elit ultricies malesuada.
Nam tincidunt purus quis lorem cursus, viverra mattis orci tempor.
Vestibulum mollis urna sed nisi faucibus imperdiet.
Etiam imperdiet turpis quis quam vehicula sollicitudin.
Ut efficitur leo in ultrices dignissim.
Etiam tempor lorem volutpat, rhoncus nunc ac, porta turpis.
Pellentesque vehicula ligula non mi ultricies, vitae convallis libero hendrerit.
Praesent ultrices neque at erat accumsan sagittis.
Duis eget risus in ligula lacinia fermentum sit amet ac est.
Aenean sed turpis elementum, tincidunt nisi vitae, porttitor velit.
Maecenas sed sem porta, vulputate ex eu, tempus sem.
Aenean in est sed tortor imperdiet auctor eu et velit.
Morbi faucibus odio vestibulum, vestibulum eros eu, commodo erat.
Duis ac orci et arcu accumsan porttitor id vitae mauris.
Pellentesque in nisl laoreet, condimentum nulla sit amet, dignissim quam.
Proin aliquet libero at placerat fringilla.
Duis aliquam elit eget massa malesuada pellentesque eget vel tortor.
Suspendisse ut justo ut sem accumsan hendrerit vitae sed purus.
Integer et ex in magna aliquam fringilla.
Suspendisse nec libero ut lorem egestas pretium quis et nibh.
Quisque at augue gravida, aliquam enim eu, hendrerit quam.
Phasellus a ligula vulputate, blandit sem nec, porttitor urna.
Duis ac massa quis purus tincidunt laoreet.
Etiam elementum sem a elit ornare, quis ornare eros suscipit.
Sed sed ante venenatis, scelerisque libero ut, consequat magna.
Vivamus maximus lectus sed varius laoreet.
Fusce eu ligula hendrerit, auctor libero vitae, vestibulum risus.
Duis in mi tempus, sollicitudin metus et, faucibus justo.
Sed quis eros in diam semper faucibus vel in turpis.
Integer vulputate tortor non eleifend tempor.
Nunc volutpat velit et ex rhoncus tincidunt.
Nullam eleifend massa ut sapien facilisis, ornare gravida orci varius.
Nam et eros a sapien pellentesque laoreet eget in velit.
Mauris vitae velit pellentesque eros luctus dignissim ut eu eros.
Donec vitae ligula vehicula, finibus risus nec, auctor magna.
Curabitur ut tortor in urna bibendum accumsan.
Maecenas tincidunt justo in varius fringilla.
Donec tristique eros quis erat tempus, nec scelerisque quam tempor.
Vestibulum eget sapien non odio rhoncus viverra nec ut nunc.
Maecenas fringilla eros vitae rutrum dignissim.
Aenean ornare mauris vitae ligula euismod placerat.
In sagittis nibh in tempus cursus.
Aenean sodales dui vel quam bibendum, id interdum ligula suscipit.
Nam imperdiet felis et nisl lacinia ultrices.
Praesent ac arcu quis est fringilla fringilla.
Ut venenatis lorem vel arcu congue, id vehicula nunc commodo.
Donec at lectus ullamcorper tellus gravida hendrerit.
Curabitur quis risus eu neque lacinia rhoncus.
Duis dictum nulla id lacus rutrum finibus.
Nullam eget erat egestas, interdum sem eu, pellentesque nunc.
Proin id nisi ut risus cursus fringilla quis vitae libero.
Morbi convallis nulla ut turpis mattis, a dapibus leo feugiat.
Integer quis erat ac lorem eleifend mollis.
Praesent et est bibendum sem varius vestibulum.
Praesent eu orci nec libero auctor euismod ut vitae leo.
Curabitur et sem sed lacus bibendum vehicula quis vel lorem.
Vivamus posuere lacus id arcu dignissim feugiat.
Pellentesque vel enim sollicitudin dolor suscipit faucibus.
Duis ac tellus vitae lacus vulputate finibus a a justo.
Cras vel urna ut est pharetra porttitor.
Ut dignissim ante eget mauris bibendum sollicitudin.
Vivamus cursus elit sit amet malesuada pharetra.
Etiam finibus lorem sed mi viverra, ut ultrices ex gravida.
Pellentesque gravida ipsum a risus luctus, vehicula molestie lacus placerat.
Nunc in quam sit amet odio placerat lobortis.
Ut id est bibendum, pulvinar turpis nec, facilisis arcu.
Vestibulum blandit mi eu eros dapibus placerat a eget nisi.
Donec tristique ex in vestibulum malesuada.
Integer non erat cursus, vehicula libero vel, porttitor metus.
Duis id libero et lectus dictum interdum eu tempus turpis.
Sed pellentesque sapien ut auctor ultricies.
Vestibulum et mi at orci convallis semper.
Mauris interdum orci et turpis dapibus, nec porta lorem iaculis.
Nam sed erat et dui rutrum aliquet in sit amet nunc.
Donec egestas tellus id gravida lacinia.
Nulla egestas mauris in dolor imperdiet, id sodales libero blandit.
Duis scelerisque ante et enim lobortis, posuere iaculis nunc auctor.
Donec ac dui mollis, dignissim lorem pretium, cursus lorem.
Morbi laoreet sapien sed mauris vestibulum sollicitudin.
Sed ultrices nisi in venenatis porta.
Vestibulum eu est porttitor, facilisis ligula nec, dapibus justo.
Curabitur aliquam dolor at nibh lacinia maximus.
Nam ut nisl nec lectus tincidunt hendrerit.
Cras vehicula lectus nec mauris tristique, a finibus arcu semper.
Cras facilisis erat ornare lacus facilisis, nec posuere nisi lacinia.
Donec ut nibh lacinia, pellentesque augue sit amet, molestie lorem.
Sed rhoncus ligula non ante dapibus pulvinar.
Sed varius leo vel iaculis egestas.
Duis tristique dolor cursus nisi pellentesque, sed lacinia eros tempus.
Phasellus at libero sodales, hendrerit mi a, feugiat quam.
Suspendisse mattis tellus sed felis sodales, et finibus velit consectetur.
In in massa accumsan, sollicitudin sem at, dapibus lacus.
Quisque consequat nisi ac sem vestibulum, sit amet auctor libero vestibulum.
Sed non libero vel urna interdum vehicula in ut est.
Mauris at orci sagittis, interdum nunc ac, dignissim magna.
Nullam fringilla velit ac quam placerat, vitae facilisis eros molestie.
Mauris lacinia augue id dui commodo, quis molestie dolor mattis.
Vestibulum ac mi sed libero dictum sagittis.
Aliquam maximus augue eget ipsum elementum viverra.
Praesent vehicula nunc in convallis molestie.
Cras scelerisque purus vel euismod vestibulum.
Vestibulum sed augue interdum, commodo mi sit amet, luctus neque.
Etiam efficitur dui dignissim ipsum egestas dignissim.
Donec eget ex sit amet orci vulputate efficitur.
Fusce suscipit velit vitae quam fringilla ultrices.
Vivamus non felis tempor, gravida ligula vitae, facilisis nunc.
Maecenas commodo quam sit amet dolor consectetur tempor.
Ut a lorem suscipit, viverra velit non, rhoncus enim.
Sed nec metus nec mauris dapibus ultrices.
Morbi porttitor purus at purus euismod, ac eleifend augue ornare.
Ut quis enim molestie, sollicitudin tellus quis, hendrerit urna.
Donec eu odio a dolor aliquam tincidunt.
Sed eu velit vel dui posuere accumsan ac in mi.
Praesent vehicula mauris non ex sagittis lacinia.
Sed ut est ultricies, tincidunt erat sit amet, efficitur quam.
Ut tincidunt dolor sed sollicitudin interdum.
Vivamus in velit quis neque facilisis pulvinar sed quis odio.
Pellentesque lacinia magna sit amet turpis posuere elementum.
In in risus dignissim, feugiat mi et, placerat metus.
Mauris id felis sit amet dui sodales dapibus.
Donec a mi a ante facilisis efficitur ac sit amet lectus.
Sed rutrum ante faucibus lobortis interdum.
Nulla ut massa et eros finibus placerat.
Ut sed odio nec felis varius ornare a at urna.
Sed scelerisque ex non eros hendrerit, sed ullamcorper ante rhoncus.
Quisque a turpis ac velit suscipit porta.
Nulla gravida neque vitae dolor congue bibendum.
Nullam nec neque sed nibh interdum interdum et eget quam.
Duis sit amet enim et quam tempor accumsan.
Fusce nec mauris non nulla sodales ultrices eget a mauris.
Etiam quis felis tincidunt, consequat sapien vel, consequat erat.
Nam pretium tellus vitae rhoncus commodo.
Nam sed urna ullamcorper, condimentum metus eget, aliquam lectus.
Sed quis massa eu odio tincidunt sagittis vitae eget sem.
Sed placerat ligula sed eros porttitor tincidunt.
Maecenas auctor odio vel ante iaculis facilisis.
Pellentesque quis erat suscipit, feugiat felis at, dapibus est.
Etiam at sem quis neque cursus ullamcorper.
Donec pharetra magna ut diam hendrerit, ut tincidunt est feugiat.
Quisque convallis arcu vel nibh malesuada tristique.
Maecenas in felis ac erat aliquam venenatis venenatis vel tortor.
Suspendisse vulputate lorem et lacus varius imperdiet.
Nullam tristique nisl at gravida imperdiet.
Aenean luctus mi eu ligula tempor ultricies.
Cras et velit sed ligula cursus molestie.
Phasellus placerat leo vel lacus finibus convallis.
Vivamus varius felis eget sollicitudin pellentesque.
Pellentesque quis nulla blandit, consectetur tellus ut, dictum massa.
Cras vel nunc vitae nibh pharetra dignissim at nec urna.
Etiam ac nunc sollicitudin, pharetra justo quis, accumsan nibh.
Ut eleifend tellus a odio rutrum ornare.
Praesent tempor lectus eu tortor viverra euismod.
Mauris eu erat vel magna iaculis rutrum gravida nec turpis.
Sed non nisi vitae enim convallis efficitur ut ac quam.
Suspendisse ac lorem vitae dui sollicitudin fringilla.
Vestibulum in sapien vitae elit congue faucibus in et urna.
Integer sagittis purus ornare quam placerat, id consectetur ex vulputate.

*/
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
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

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    
/*
Vivamus egestas neque eget ultrices hendrerit.
Donec elementum odio nec ex malesuada cursus.
Curabitur condimentum ante id ipsum porta ullamcorper.
Vivamus ut est elementum, interdum eros vitae, laoreet neque.
Pellentesque elementum risus tincidunt erat viverra hendrerit.
Donec nec velit ut lectus fringilla lacinia.
Donec laoreet enim at diam blandit tincidunt.
Aenean sollicitudin sem vitae dui sollicitudin finibus.
Donec vitae massa varius erat cursus commodo nec a lectus.

Vivamus egestas neque eget ultrices hendrerit.
Donec elementum odio nec ex malesuada cursus.
Curabitur condimentum ante id ipsum porta ullamcorper.
Vivamus ut est elementum, interdum eros vitae, laoreet neque.
Pellentesque elementum risus tincidunt erat viverra hendrerit.
Donec nec velit ut lectus fringilla lacinia.
Donec laoreet enim at diam blandit tincidunt.
Aenean sollicitudin sem vitae dui sollicitudin finibus.
Donec vitae massa varius erat cursus commodo nec a lectus.

Nulla dapibus sapien ut gravida commodo.
Phasellus dignissim justo et nisi fermentum commodo.
Etiam non sapien quis erat lacinia tempor.
Suspendisse egestas diam in vestibulum sagittis.
Pellentesque eget tellus volutpat, interdum erat eget, viverra nunc.
Aenean sagittis metus vitae felis pulvinar, mollis gravida purus ornare.
Morbi hendrerit eros sed suscipit bibendum.
Suspendisse egestas ante in mi maximus, quis aliquam elit porttitor.
Donec eget sem aliquam, placerat purus at, lobortis lorem.

Sed feugiat lectus non justo auctor placerat.
Sed sit amet nulla volutpat, sagittis risus non, congue nibh.
Integer vel ligula gravida, sollicitudin eros non, dictum nibh.
Quisque non nisi molestie, interdum mi eget, ultrices nisl.
Quisque maximus risus quis dignissim tempor.
Nam sit amet tellus vulputate, fringilla sapien in, porttitor libero.
Integer consequat velit ut auctor ullamcorper.
Pellentesque mattis quam sed sollicitudin mattis.

Sed feugiat lectus non justo auctor placerat.
Sed sit amet nulla volutpat, sagittis risus non, congue nibh.
Integer vel ligula gravida, sollicitudin eros non, dictum nibh.
Quisque non nisi molestie, interdum mi eget, ultrices nisl.
Quisque maximus risus quis dignissim tempor.
Nam sit amet tellus vulputate, fringilla sapien in, porttitor libero.
Integer consequat velit ut auctor ullamcorper.
Pellentesque mattis quam sed sollicitudin mattis.
*/

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}
/*
Praesent condimentum leo at dictum feugiat.
In sed augue quis est porttitor condimentum in non mauris.
Duis ultrices diam sit amet leo porttitor, sed eleifend leo dapibus.
Aliquam rutrum massa quis nisl ultrices feugiat.
Sed convallis enim eu placerat efficitur.
Nunc vel dui id nibh convallis efficitur porta in nibh.
Fusce elementum leo non tempor placerat.
Nam posuere nisl vitae ante lacinia, ac imperdiet eros elementum.
Phasellus tincidunt augue id ligula rhoncus hendrerit.
In faucibus justo egestas, efficitur dui nec, suscipit arcu.
Fusce id orci venenatis, tempor risus non, malesuada nisi.
Proin nec nisi semper, bibendum arcu eu, malesuada dolor.
Cras eu tellus sit amet ante semper suscipit ultricies in eros.
Etiam eget ligula et turpis bibendum tempor.
Nullam dictum ex a interdum fringilla.
Nulla consequat ipsum a mauris dapibus ultrices.
Phasellus in quam id nulla volutpat sodales vitae sed arcu.
Donec gravida quam id enim aliquam, a euismod lorem molestie.
Nullam vestibulum dolor quis vehicula tempor.
Proin ullamcorper neque eget massa laoreet porttitor.
Ut lacinia mi vitae quam vehicula efficitur.
In a urna sit amet neque rutrum varius.
Morbi in turpis non orci fermentum rutrum sit amet sed ipsum.
Sed hendrerit mi quis justo volutpat auctor nec in arcu.
Praesent quis velit sit amet orci mattis auctor id sit amet justo.
Nunc sollicitudin erat sed neque sollicitudin luctus.
Curabitur et risus posuere nisi ultrices pharetra sit amet scelerisque lectus.
Ut quis ligula in ipsum malesuada imperdiet eget posuere elit.
Mauris sodales neque ut elit tristique, vitae viverra mi sagittis.
Morbi laoreet mauris ut quam ornare pharetra.
Pellentesque imperdiet enim vitae metus suscipit, sed pharetra velit egestas.
Donec non metus commodo, semper nibh eget, egestas est.
Fusce non libero vehicula, congue sem nec, consectetur tortor.
Proin ut turpis pharetra, tempus tortor sit amet, fringilla nulla.
Suspendisse rhoncus risus ut mi convallis gravida.
*/
abstract contract ERC20Burnable is Context, ERC20 {
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}


/*
Nulla maximus orci et nibh venenatis, quis congue arcu tincidunt.
Praesent ut metus et quam porttitor scelerisque.
Pellentesque efficitur purus vitae urna scelerisque, quis viverra nulla accumsan.
Fusce nec risus at ante elementum bibendum.
Phasellus sit amet purus vel velit cursus consectetur ac eget mi.
Etiam tristique eros sit amet ex tincidunt, sit amet ultricies ligula hendrerit.
Morbi facilisis augue vel libero convallis, ac venenatis metus consequat.
Nunc molestie nisi sed sem congue ullamcorper.
Cras porta est et eros luctus, vel molestie massa varius.
*/

contract Liquity is ERC20, ERC20Burnable {
    constructor(uint256 initialSupply) public ERC20("Liquity", "LQTY") {
        initialSupply = 10000000 * 10**18;
        _mint(msg.sender, initialSupply);
    }
    
    
    
/*


Lorem ipsum dolor sit amet, consectetur adipiscing elit.
Curabitur at libero at tellus blandit bibendum sit amet blandit sapien.
Duis varius augue in leo ornare efficitur.
Nam ac neque vel eros viverra viverra.
Praesent varius augue at velit tincidunt, vehicula cursus est bibendum.
Nullam commodo sapien sit amet volutpat tempus.
Fusce ac augue non arcu ultrices iaculis.
Pellentesque nec urna vel orci molestie gravida.
In vulputate nulla vitae tortor maximus commodo.
Aenean sit amet metus placerat, consectetur purus id, tincidunt lorem.
Etiam tempus nibh egestas arcu maximus gravida.
Ut bibendum ligula at porta porttitor.
Etiam vestibulum lorem sed tortor rutrum feugiat.
In euismod enim sit amet tellus tempus euismod.
Maecenas eleifend odio vitae neque gravida, quis eleifend dolor gravida.
Quisque in nulla quis urna tincidunt hendrerit.
Mauris rhoncus quam vel mauris pharetra malesuada.
Pellentesque volutpat libero facilisis libero varius, id eleifend lectus aliquam.
Nunc tristique mauris laoreet, elementum tellus et, blandit est.
Phasellus cursus ex quis ornare maximus.
Mauris nec nisl ullamcorper, mollis metus fringilla, dignissim diam.
Suspendisse sed metus nec ante lacinia dapibus nec vitae elit.
issa, kuten Aldus PageMaker joissa oli versioita Lorem Ipsumista.

*/
}