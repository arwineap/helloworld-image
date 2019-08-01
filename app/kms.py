"""Setup helper functions for secrets."""
import boto3
import base64

kms = boto3.client('kms')


def encrypt(secret, alias):
    """Encrypt secret."""
    ciphertext = kms.encrypt(KeyId=alias, Plaintext=bytes(secret, encoding='utf8'))
    return base64.b64encode(ciphertext["CiphertextBlob"]).decode('utf8')


def decrypt(secret):
    """Decrypt secret."""
    plaintext = kms.decrypt(CiphertextBlob=bytes(base64.b64decode(secret)))
    return plaintext["Plaintext"].decode('utf8')
