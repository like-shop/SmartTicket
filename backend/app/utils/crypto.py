import base64
import os
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.primitives import padding

from app.config import settings


def _get_key() -> bytes:
    key = settings.PLATFORM_PASSWORD_ENCRYPTION_KEY
    if len(key) < 32:
        key = key.ljust(32, "0")
    return key[:32].encode("utf-8")


def encrypt_password(plain_text: str) -> str:
    key = _get_key()
    iv = os.urandom(16)
    padder = padding.PKCS7(128).padder()
    padded_data = padder.update(plain_text.encode("utf-8")) + padder.finalize()

    cipher = Cipher(algorithms.AES(key), modes.CBC(iv))
    encryptor = cipher.encryptor()
    encrypted = encryptor.update(padded_data) + encryptor.finalize()

    return base64.b64encode(iv + encrypted).decode("utf-8")


def decrypt_password(encrypted_text: str) -> str:
    key = _get_key()
    raw = base64.b64decode(encrypted_text)
    iv = raw[:16]
    encrypted = raw[16:]

    cipher = Cipher(algorithms.AES(key), modes.CBC(iv))
    decryptor = cipher.decryptor()
    padded_data = decryptor.update(encrypted) + decryptor.finalize()

    unpadder = padding.PKCS7(128).unpadder()
    plain = unpadder.update(padded_data) + unpadder.finalize()

    return plain.decode("utf-8")
