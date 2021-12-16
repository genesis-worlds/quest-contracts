// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract ERC721Base is ERC721Enumerable, ERC721URIStorage, AccessControlEnumerable {
    // BaseURI for the token metadata
    string private _internalBaseURI;

    /**
     * @dev Initializes the contract by setting a `name`, a `symbol` and a `baseURI` to the token collection.
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI
    ) ERC721(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _internalBaseURI = baseURI;
    }

    modifier onlyAdmin {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "ERC721: must have admin role"
        );
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, AccessControlEnumerable, ERC721)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Sets the baseURI for {tokenURI}
     */
    function setBaseURI(string memory newBaseUri) public onlyAdmin {
        _internalBaseURI = newBaseUri;
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyAdmin {
        super._setTokenURI(tokenId, _tokenURI);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     */
    function setBatchTokenURIs(uint256[] memory tokenIds, string[] memory _tokenURIs) public onlyAdmin {
        require(tokenIds.length == _tokenURIs.length, "ERC721: mismatched ids and URIs");
        for (uint256 i=0; i<tokenIds.length; i=i+1) {
            super._setTokenURI(tokenIds[i], _tokenURIs[i]);
        }
    }

    /**
     * @dev Mints a new token to `to`.
     *
     * `tokenId` of tokens increments from 1.
     *
     */
    function mint(address to, uint256 tokenId) public virtual onlyAdmin {
        _mint(to, tokenId);
    }

    /**
     * @dev Mints new tokens to `to`.
     */
    function batchMint(address to, uint256[] memory tokenIds) public virtual onlyAdmin {
        for (uint256 i=0; i<tokenIds.length; i+=1) {
            _mint(to, tokenIds[i]);
        }
    }

    /**
     * @dev Destroys hiro.
     */
    function burn(uint256 tokenId) public virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    /**
     * @dev Transfer multiple tokens.
     */
    function batchTransferFrom(
        address from,
        address to,
        uint256[] memory tokenIds
    ) public virtual {
        for (uint256 i=0; i<tokenIds.length; i+=1) {
            require(_isApprovedOrOwner(_msgSender(), tokenIds[i]), "ERC721: transfer caller is not owner nor approved");

            _transfer(from, to, tokenIds[i]);
        }
    }

    /**
     * @dev Returns the owner of this contract.
     *
     * Admin at index 0 is returned as the owner of this contract. This is for opensea support.
     *
     */
    function owner() public view returns (address) {
        return getRoleMember(DEFAULT_ADMIN_ROLE, 0);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721URIStorage, ERC721)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return _internalBaseURI;
    }
}
