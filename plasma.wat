(module
  ;; Import sin from JS
  (import "" "s" (func $sin (param f64) (result f64)))
  ;; 1 page = 64KB, enough for 256x256x4 = 262144 bytes
  (memory (export "m") 4)

  (func (export "r") (param $t f64)
    (local $i i32)
    (local $x f64)
    (local $y f64)
    (local $v f64)
    (local $u f64)
    (local $w f64)

    ;; Loop over 256x256 pixels
    (loop $L
      ;; x = (i/4) & 255 - 128  (centered)
      (local.set $x (f64.convert_i32_s (i32.sub
        (i32.and (i32.shr_u (local.get $i) (i32.const 2)) (i32.const 255))
        (i32.const 128))))
      ;; y = (i/4) >> 8 - 128  (centered)
      (local.set $y (f64.convert_i32_s (i32.sub
        (i32.shr_u (local.get $i) (i32.const 10))
        (i32.const 128))))

      ;; Rotozoom: rotate (x,y) by time
      ;; u = x*cos(t*0.3) - y*sin(t*0.3)   (cos = sin(x + 1.5708))
      ;; w = x*sin(t*0.3) + y*cos(t*0.3)
      (local.set $u (f64.sub
        (f64.mul (local.get $x) (call $sin (f64.add (f64.mul (local.get $t) (f64.const 0.3)) (f64.const 1.5708))))
        (f64.mul (local.get $y) (call $sin (f64.mul (local.get $t) (f64.const 0.3))))))
      (local.set $w (f64.add
        (f64.mul (local.get $x) (call $sin (f64.mul (local.get $t) (f64.const 0.3))))
        (f64.mul (local.get $y) (call $sin (f64.add (f64.mul (local.get $t) (f64.const 0.3)) (f64.const 1.5708))))))

      ;; Plasma: v = sin(u*0.03 + t) + sin(w*0.04 + t*0.7) + sin((u+w)*0.02 + t*0.5)
      (local.set $v (f64.add
        (f64.add
          (call $sin (f64.add (f64.mul (local.get $u) (f64.const 0.03)) (local.get $t)))
          (call $sin (f64.add (f64.mul (local.get $w) (f64.const 0.04)) (f64.mul (local.get $t) (f64.const 0.7)))))
        (call $sin (f64.add
          (f64.mul (f64.add (local.get $u) (local.get $w)) (f64.const 0.02))
          (f64.mul (local.get $t) (f64.const 0.5))))))

      ;; Store RGBA pixel:
      ;; r = sin(v * 3.14159) * 127 + 128
      ;; g = sin(v * 3.14159 + 2.094) * 127 + 128
      ;; b = sin(v * 3.14159 + 4.189) * 127 + 128
      ;; a = 255
      (i32.store (local.get $i)
        (i32.or (i32.or (i32.or
          ;; R
          (i32.trunc_f64_s (f64.add
            (f64.mul (call $sin (f64.mul (local.get $v) (f64.const 3.14159))) (f64.const 127.0))
            (f64.const 128.0)))
          ;; G << 8
          (i32.shl (i32.trunc_f64_s (f64.add
            (f64.mul (call $sin (f64.add (f64.mul (local.get $v) (f64.const 3.14159)) (f64.const 2.094))) (f64.const 127.0))
            (f64.const 128.0)))
            (i32.const 8)))
          ;; B << 16
          (i32.shl (i32.trunc_f64_s (f64.add
            (f64.mul (call $sin (f64.add (f64.mul (local.get $v) (f64.const 3.14159)) (f64.const 4.189))) (f64.const 127.0))
            (f64.const 128.0)))
            (i32.const 16)))
          ;; A << 24
          (i32.const 0xFF000000)))

      ;; i += 4, loop if < 262144
      (br_if $L (i32.lt_u
        (local.tee $i (i32.add (local.get $i) (i32.const 4)))
        (i32.const 262144)))
    )
  )
)
