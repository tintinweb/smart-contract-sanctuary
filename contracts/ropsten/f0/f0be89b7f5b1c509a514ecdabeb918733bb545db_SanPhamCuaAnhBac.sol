/**
 *Submitted for verification at Etherscan.io on 2021-04-18
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

//khai báo phiên bản sử dụng của solidity
pragma solidity >=0.4.25;
//khai báo cái này thì hàm getAllProduct mới hoạt động được
pragma experimental ABIEncoderV2;

//đặt tên của smart contract ở đây
contract SanPhamCuaAnhBac{

    //owner là người quản lý của cái smart contract
    address owner;
    //số thứ tự của sản phẩm nhập vào, sản phẩm đầu tiên sẽ là 1
    uint public productCount = 1;

    //khai báo đối tượng Product (sản phẩm)
    // sau này nếu muốn thêm các Ngày sản xuất, hạn sử dụng,... sẽ thêm vào trong cái này
    struct Product 
    {
            uint id;
            string name;
            string serlialNo;
            string price;
            string dateCreate;
            string userName;
            string companyName;
            string addressCompany;
            string nationCompany;
            //ví dụ thêm Hạn sử dụng
            // string HSD;
    }
    
    //đây là khai báo 1 danh sách sản phẩm, cứ thêm mới sản phẩm sẽ cộng thêm vào đây
    Product[] public listProduct;


    //cái này là cái event, nó không có tác dụng gì nhiều, chỉ để báo cho mình biết thôi
    event ProductCreated
    (
        uint id,
        string name,
        string serlialNo,
        string price,
        string dateCreate,
        string userName,
        string companyName,
        string addressCompany,
        string nationCompany
    );

    constructor() public {
        //hàm này nghĩa là ai là người đưa smart contract lên mạng ethereum thì là người quản lý
        owner = msg.sender;
    }


    //hàm tạo sản phẩm mới
    function createProduct(string _name, string _serialNo, string _price, string _dateCreate, string _userName,
    string _companyName, string _addressCompany, string _nationCompany) public {
        //yêu cầu giá của sản phẩm không được là số Âm
        //khai báo 1 sản phẩm mới
        Product memory p;
        //gán số thứ tự bằng productCount
        //sau khi gán thì productCount tự động + thêm 1 đơn vị
        p.id = productCount++;
        //gán tên sản phẩm
        p.name = _name;
        //gán mã số
        p.serlialNo = _serialNo;
        //gán giá
        p.price = _price;
        p.dateCreate = _dateCreate;
        p.userName = _userName;
        p.companyName = _companyName;
        p.addressCompany = _addressCompany;
        p.nationCompany = _nationCompany;
        
        //thêm sản phẩm vừa tạo vào danh sách
        listProduct.push(p);

        // Trigger an event
        //nhập cái event để mình biết event này có xảy ra, k có cũng k sao
        emit ProductCreated(productCount, _name, _serialNo, _price,_dateCreate, _userName, _companyName, _addressCompany,_nationCompany);
    }

    //hàm tìm sản phẩm theo mã số
    function getProduct(string serlialNo) view public returns(string) {
        Product  p;
        //gán sản phẩm cần tìm có số thứ tự là 0
        p.id = 0;
        //dò trong cái danh sách từ đầu tới cuối
         for (uint i = 0; i < listProduct.length; i++) {
            if(keccak256(listProduct[i].serlialNo) == keccak256(serlialNo) ) {
                //dò đến khi nào có hai cái mã số bằng nhau
                //thì trả về cái sản phẩm đó
                p = listProduct[i];
                break;
            }
    }
        //trả về sản phẩm đó
        // lưu ý, nếu số thứ tự sản phẩm khác 0, là tìm thấy, còn nếu = 0 là không tìm thấy sản phẩm với mã số tương ứng
        // return(p.id, p.name, p.serlialNo, p.price);
        // return p.name;
        return string(abi.encodePacked(p.name, "---", p.serlialNo, "---", p.price, "---", p.dateCreate,
        "---", p.userName, "---", p.companyName, "---", p.addressCompany, "---", p.nationCompany));
    }
    
    //lấy tất cả sản phẩm
    function getAllProduct() view public returns (Product[] list) {
        return listProduct;
    }
}