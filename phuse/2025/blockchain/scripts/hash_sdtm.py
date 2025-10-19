import hashlib, json, sys, pathlib, time

def sha256_file(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(8192), b''):
            h.update(chunk)
    return h.hexdigest()

def sha256_json(path):
    obj = json.loads(pathlib.Path(path).read_text())
    # canonicalize: sort keys, no whitespace variance
    canon = json.dumps(obj, sort_keys=True, separators=(',', ':')).encode('utf-8')
    return hashlib.sha256(canon).hexdigest(), canon.decode()

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python hash_sdtm.py <filetype:csv|json> <path>")
        sys.exit(1)
    t, p = sys.argv[1], sys.argv[2]
    t0 = time.time()
    if t == 'csv':
        digest = sha256_file(p)
        print(f"SHA256({p})={digest}")
    elif t == 'json':
        digest, canon = sha256_json(p)
        print(f"SHA256({p})={digest}")
    else:
        raise SystemExit("filetype must be csv|json")
    print(f"elapsed_ms={(time.time()-t0)*1000:.2f}")
