(module
  (import "" "s" (func $sin (param f64) (result f64)))
  (memory (export "m") 4)

  (func (export "r") (param $t f64)
    (local $i i32)
    (local $x f64)
    (local $y f64)
    (local $v f64)
    (local $u f64)
    (local $w f64)
    (local $a f64)
    (local $z f64)
    (local $ca f64)
    (local $sa f64)

    ;; Rotation with wobble
    (local.set $a (f64.add
      (f64.mul (local.get $t) (f64.const 0.3))
      (f64.mul (call $sin (f64.mul (local.get $t) (f64.const 0.17))) (f64.const 0.7))))

    ;; Pulsing zoom
    (local.set $z (f64.add (f64.const 0.6)
      (f64.mul (call $sin (f64.mul (local.get $t) (f64.const 0.23))) (f64.const 0.4))))

    ;; Precompute sin/cos
    (local.set $sa (call $sin (local.get $a)))
    (local.set $ca (call $sin (f64.add (local.get $a) (f64.const 1.5708))))

    (loop $L
      (local.set $x (f64.convert_i32_s (i32.sub
        (i32.and (i32.shr_u (local.get $i) (i32.const 2)) (i32.const 255))
        (i32.const 128))))
      (local.set $y (f64.convert_i32_s (i32.sub
        (i32.shr_u (local.get $i) (i32.const 10))
        (i32.const 128))))

      ;; Rotozoom
      (local.set $u (f64.mul (f64.sub
        (f64.mul (local.get $x) (local.get $ca))
        (f64.mul (local.get $y) (local.get $sa))) (local.get $z)))
      (local.set $w (f64.mul (f64.add
        (f64.mul (local.get $x) (local.get $sa))
        (f64.mul (local.get $y) (local.get $ca))) (local.get $z)))

      ;; Per-pixel warp distortion (subtle)
      (local.set $u (f64.add (local.get $u)
        (f64.mul (call $sin (f64.add
          (f64.mul (local.get $w) (f64.const 0.04))
          (local.get $t))) (f64.const 3.0))))
      (local.set $w (f64.add (local.get $w)
        (f64.mul (call $sin (f64.add
          (f64.mul (local.get $u) (f64.const 0.03))
          (f64.mul (local.get $t) (f64.const 0.7)))) (f64.const 3.0))))

      ;; 5-wave plasma
      (local.set $v (f64.add (f64.add (f64.add (f64.add
        (call $sin (f64.add (f64.mul (local.get $u) (f64.const 0.03)) (local.get $t)))
        (call $sin (f64.add (f64.mul (local.get $w) (f64.const 0.037))
          (f64.mul (local.get $t) (f64.const 0.7)))))
        (call $sin (f64.add
          (f64.mul (f64.add (local.get $u) (local.get $w)) (f64.const 0.02))
          (f64.mul (local.get $t) (f64.const 0.5)))))
        ;; radial
        (call $sin (f64.sub
          (f64.mul (f64.add
            (f64.mul (local.get $u) (local.get $u))
            (f64.mul (local.get $w) (local.get $w))) (f64.const 0.00015))
          (f64.mul (local.get $t) (f64.const 0.9)))))
        ;; diagonal
        (call $sin (f64.add
          (f64.sub (f64.mul (local.get $u) (f64.const 0.015))
                   (f64.mul (local.get $w) (f64.const 0.021)))
          (f64.mul (local.get $t) (f64.const 1.3))))))

      ;; Cycling rainbow palette
      (i32.store (local.get $i)
        (i32.or (i32.or (i32.or
          (i32.trunc_f64_s (f64.add
            (f64.mul (call $sin (f64.add
              (f64.mul (local.get $v) (f64.const 3.14159))
              (f64.mul (local.get $t) (f64.const 0.4)))) (f64.const 127.0))
            (f64.const 128.0)))
          (i32.shl (i32.trunc_f64_s (f64.add
            (f64.mul (call $sin (f64.add (f64.add
              (f64.mul (local.get $v) (f64.const 3.14159))
              (f64.const 2.094))
              (f64.mul (local.get $t) (f64.const 0.3)))) (f64.const 127.0))
            (f64.const 128.0))) (i32.const 8)))
          (i32.shl (i32.trunc_f64_s (f64.add
            (f64.mul (call $sin (f64.add (f64.add
              (f64.mul (local.get $v) (f64.const 3.14159))
              (f64.const 4.189))
              (f64.mul (local.get $t) (f64.const 0.5)))) (f64.const 127.0))
            (f64.const 128.0))) (i32.const 16)))
          (i32.const 0xFF000000)))

      (br_if $L (i32.lt_u
        (local.tee $i (i32.add (local.get $i) (i32.const 4)))
        (i32.const 262144)))
    )
  )
)
